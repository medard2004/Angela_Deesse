import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import '../utils/phone_normalizer.dart';
import 'external_action_tracker.dart';

class ContactLaunchResult {
  final bool success;
  final String? errorMessage;

  const ContactLaunchResult._({required this.success, this.errorMessage});

  factory ContactLaunchResult.success() => const ContactLaunchResult._(success: true);
  factory ContactLaunchResult.failure(String message) =>
      ContactLaunchResult._(success: false, errorMessage: message);
}

/// Interface pour déclencher les appels, SMS et WhatsApp réels.
abstract class ContactLauncher {
  Future<ContactLaunchResult> call(String? phone);
  Future<ContactLaunchResult> sms(String? phone, {String? body});
  Future<ContactLaunchResult> whatsapp(String? phone, {String? body});
}

/// Implémentation réelle utilisant [url_launcher] et [ExternalActionTracker].
class DefaultContactLauncher implements ContactLauncher {
  DefaultContactLauncher({
    Future<bool> Function(Uri url, {ul.LaunchMode mode})? launcher,
    ExternalActionTracker? tracker,
    String Function()? getDefaultCountryCode,
  })  : _launcher = launcher ?? ul.launchUrl,
        _tracker = tracker,
        _getDefaultCountryCode = getDefaultCountryCode;

  final Future<bool> Function(Uri url, {ul.LaunchMode mode}) _launcher;
  final ExternalActionTracker? _tracker;
  final String Function()? _getDefaultCountryCode;

  String _getCountryCode() => _getDefaultCountryCode?.call() ?? '228';

  @override
  Future<ContactLaunchResult> call(String? phone) async {
    final norm = normalizePhoneNumber(phone, defaultCountryCode: _getCountryCode());
    if (!norm.isValid) {
      return ContactLaunchResult.failure(norm.error!);
    }

    final uri = Uri(scheme: 'tel', path: norm.e164);
    return _launchWithTracker(
      uri,
      defaultErrorMessage: 'Impossible de passer l\'appel',
    );
  }

  @override
  Future<ContactLaunchResult> sms(String? phone, {String? body}) async {
    final norm = normalizePhoneNumber(phone, defaultCountryCode: _getCountryCode());
    if (!norm.isValid) {
      return ContactLaunchResult.failure(norm.error!);
    }

    final Uri uri;
    if (body == null || body.isEmpty) {
      uri = Uri(scheme: 'sms', path: norm.e164);
    } else if (!kIsWeb && Platform.isIOS) {
      // Séparateur iOS '&' documenté pour le corps de SMS
      final encodedBody = Uri.encodeComponent(body);
      uri = Uri.parse('sms:${norm.e164}&body=$encodedBody');
    } else {
      // Séparateur standard '?' pour Android et autres plateformes
      uri = Uri(
        scheme: 'sms',
        path: norm.e164,
        queryParameters: {'body': body},
      );
    }

    return _launchWithTracker(
      uri,
      defaultErrorMessage: 'Impossible d\'ouvrir les SMS',
    );
  }

  @override
  Future<ContactLaunchResult> whatsapp(String? phone, {String? body}) async {
    final norm = normalizePhoneNumber(phone, defaultCountryCode: _getCountryCode());
    if (!norm.isValid) {
      return ContactLaunchResult.failure(norm.error!);
    }

    // WhatsApp utilise les chiffres purs sans le '+' (https://wa.me/<number>)
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/${norm.digitsOnly}',
      queryParameters: (body != null && body.isNotEmpty) ? {'text': body} : null,
    );

    return _launchWithTracker(
      uri,
      defaultErrorMessage: 'Impossible d\'ouvrir WhatsApp',
    );
  }

  Future<ContactLaunchResult> _launchWithTracker(
    Uri uri, {
    required String defaultErrorMessage,
  }) async {
    try {
      Future<bool> launchAction() => _launcher(
            uri,
            mode: ul.LaunchMode.externalApplication,
          );

      final ok = _tracker != null
          ? await _tracker.runExternal(launchAction)
          : await launchAction();

      if (!ok) {
        return ContactLaunchResult.failure(defaultErrorMessage);
      }
      return ContactLaunchResult.success();
    } catch (_) {
      return ContactLaunchResult.failure(defaultErrorMessage);
    }
  }
}
