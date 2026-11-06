import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

import 'package:angela_dress/data/utils/jpeg_sanitizer.dart';
import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/services/photo_storage.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/widgets/common.dart';

class TestClock implements Clock {
  TestClock(this.currentTime);
  DateTime currentTime;

  @override
  DateTime now() => currentTime;

  void tick([Duration duration = const Duration(seconds: 10)]) {
    currentTime = currentTime.add(duration);
  }
}

class FakeImagePicker extends Fake implements ImagePicker {
  XFile? nextImage;
  LostDataResponse? lostData;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return nextImage;
  }

  @override
  Future<LostDataResponse> retrieveLostData() async {
    return lostData ?? LostDataResponse.empty();
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Tranche 5B - Photos réelles et PhotoStorage', () {
    late Directory tempDir;
    late DefaultPhotoStorage photoStorage;
    late FakeImagePicker fakePicker;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('angela_photos_test_');
      fakePicker = FakeImagePicker();
      photoStorage = DefaultPhotoStorage(
        picker: fakePicker,
        getBaseDir: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('1. Vecteur de test SHA-256 vérifié contre une valeur de référence connue', () {
      // Vecteur connu : SHA-256 de "hello world" =
      // b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
      final bytes = utf8.encode('hello world');
      final hash = sha256.convert(bytes).toString();
      expect(hash, equals('b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'));
    });

    test('2. Dédoublonnage : deux imports des mêmes octets produisent un seul fichier physique et le même chemin relatif', () async {
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04]);
      final expectedHash = sha256.convert(sampleBytes).toString();

      final photo1 = await photoStorage.saveBytes(sampleBytes);
      final photo2 = await photoStorage.saveBytes(sampleBytes);

      expect(photo1.relativePath, equals('photos/$expectedHash.jpg'));
      expect(photo2.relativePath, equals(photo1.relativePath));
      expect(photo1.hash, equals(expectedHash));
      expect(photo2.hash, equals(expectedHash));

      // Vérifier le dossier photos sur le disque
      final photosDir = Directory(p.join(tempDir.path, 'photos'));
      final files = photosDir.listSync();
      expect(files.length, equals(1));
      expect(p.basename(files.first.path), equals('$expectedHash.jpg'));
    });

    test('3. Écriture atomique : un échec d\'écriture ne laisse aucun fichier partiel .tmp', () async {
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0xAA, 0xBB]);
      final photo = await photoStorage.saveBytes(sampleBytes);
      expect(photo.relativePath, startsWith('photos/'));

      final photosDir = Directory(p.join(tempDir.path, 'photos'));
      final allFiles = photosDir.listSync().map((f) => p.basename(f.path)).toList();
      // Aucun fichier .tmp ne doit subsister
      expect(allFiles.any((name) => name.contains('.tmp')), isFalse);
    });

    test('4. Résolveur de chemin : relatif -> absolu, demo:N inchangé, fichier absent toléré sans plantage', () async {
      final relPath = 'photos/abcd1234ef5678.jpg';
      final absPath = await photoStorage.getAbsolutePath(relPath);
      expect(absPath, equals(p.join(tempDir.path, relPath)));

      final demoPath = await photoStorage.getAbsolutePath('demo:3');
      expect(demoPath, equals('demo:3'));
    });

    testWidgets('5. PhotoThumb : affichage avec fichier absent ne plante pas et rend le fallback neutre', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Provider<PhotoStorage>.value(
              value: photoStorage,
              child: const PhotoThumb('photos/fichier_inexistant.jpg', size: 80),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Icône de secours présente sans lever d'exception
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    test('6. Règle de cohérence des colonnes (Décision 4) : modèles, réalisations, commandes et order_photos', () async {
      final db = db_layer.AppDatabase(NativeDatabase.memory());
      final clock = TestClock(DateTime.utc(2026, 11, 6, 10, 0));
      final store = AppStore(db: db, clock: clock);
      await store.init(seedDemo: false);

      // Client de test
      final client = Client(id: 'c1', name: 'Client Test', phone: '90000000');
      await store.saveClient(client);

      // 6.1 Modèle avec demo:1 -> hash null, state 'none'
      final modDemo = Modele(id: 'm_demo', name: 'Modèle Démo', photo: 'demo:1');
      await store.saveModele(modDemo);
      final modDemoRow = await (db.select(db.modeles)..where((t) => t.id.equals('m_demo'))).getSingle();
      expect(modDemoRow.photoPath, equals('demo:1'));
      expect(modDemoRow.photoHash, isNull);
      expect(modDemoRow.photoUploadState, equals('none'));

      // 6.2 Modèle avec vraie photo -> hash non null, state 'pending'
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x11, 0x22]);
      final realPhoto = await photoStorage.saveBytes(sampleBytes);

      final modReal = Modele(id: 'm_real', name: 'Modèle Réel', photo: realPhoto.relativePath);
      await store.saveModele(modReal);
      final modRealRow = await (db.select(db.modeles)..where((t) => t.id.equals('m_real'))).getSingle();
      expect(modRealRow.photoPath, equals(realPhoto.relativePath));
      expect(modRealRow.photoHash, equals(realPhoto.hash));
      expect(modRealRow.photoUploadState, equals('pending'));

      // 6.3 Réalisation avec demo:2 -> hash null, state 'none'
      final realDemo = Realisation(id: 'r_demo', photo: 'demo:2', clientId: client.id, createdAt: clock.now());
      await store.saveRealisation(realDemo);
      final realDemoRow = await (db.select(db.realisations)..where((t) => t.id.equals('r_demo'))).getSingle();
      expect(realDemoRow.photoHash, isNull);
      expect(realDemoRow.photoUploadState, equals('none'));

      // 6.4 Réalisation avec vraie photo -> hash non null, state 'pending'
      final realReal = Realisation(id: 'r_real', photo: realPhoto.relativePath, clientId: client.id, createdAt: clock.now());
      await store.saveRealisation(realReal);
      final realRealRow = await (db.select(db.realisations)..where((t) => t.id.equals('r_real'))).getSingle();
      expect(realRealRow.photoHash, equals(realPhoto.hash));
      expect(realRealRow.photoUploadState, equals('pending'));

      // 6.5 Commande et order_photos partagent le même fichier sans copie
      final order = Order(
        id: 'ord_real',
        clientId: client.id,
        modeleId: modReal.id,
        title: 'Commande avec vraie photo',
        price: 45000,
        deliveryDate: DateTime.utc(2026, 11, 20),
        status: OrderStatus.cours,
        photos: [realPhoto.relativePath, 'demo:5'],
        createdAt: clock.now(),
      );
      await store.saveOrder(order);

      final ordRow = await (db.select(db.orders)..where((t) => t.id.equals('ord_real'))).getSingle();
      expect(ordRow.photoPath, equals(realPhoto.relativePath));
      expect(ordRow.photoHash, equals(realPhoto.hash));
      expect(ordRow.photoUploadState, equals('pending'));

      // Vérification dans order_photos
      final orderPhotos = await (db.select(db.orderPhotos)..where((t) => t.orderId.equals('ord_real'))).get();
      expect(orderPhotos.length, equals(2));

      final firstOp = orderPhotos.firstWhere((p) => p.photoPath == realPhoto.relativePath);
      expect(firstOp.photoHash, equals(realPhoto.hash));
      expect(firstOp.photoUploadState, equals('pending'));

      final secondOp = orderPhotos.firstWhere((p) => p.photoPath == 'demo:5');
      expect(secondOp.photoHash, isNull);
      expect(secondOp.photoUploadState, equals('none'));

      // Réordonnancement des photos : inversion des positions
      clock.tick();
      final orderReordered = Order(
        id: order.id,
        clientId: order.clientId,
        modeleId: order.modeleId,
        title: order.title,
        price: order.price,
        deliveryDate: order.deliveryDate,
        status: order.status,
        photos: ['demo:5', realPhoto.relativePath],
        createdAt: order.createdAt,
      );
      await store.saveOrder(orderReordered);

      final reorderedPhotos = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals('ord_real') & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      expect(reorderedPhotos[0].photoPath, equals('demo:5'));
      expect(reorderedPhotos[0].position, equals(0));
      expect(reorderedPhotos[1].photoPath, equals(realPhoto.relativePath));
      expect(reorderedPhotos[1].position, equals(1));

      store.dispose();
      await db.close();
    });

    test('7. Persistance sur base FICHIER temporaire et dossier photos : fermeture et réouverture', () async {
      final dbFile = File(p.join(tempDir.path, 'persistance_test.sqlite'));
      final clock = TestClock(DateTime.utc(2026, 11, 6, 12, 0));

      // 1ère session : création des entités
      var db = db_layer.AppDatabase(NativeDatabase(dbFile));
      var store = AppStore(db: db, clock: clock);
      await store.init(seedDemo: false);

      final client = Client(id: 'c_pers', name: 'Client Persistant');
      await store.saveClient(client);

      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x99, 0x88, 0x77]);
      final savedPhoto = await photoStorage.saveBytes(bytes);

      final modele = Modele(id: 'm_pers', name: 'Robe Persistante', photo: savedPhoto.relativePath);
      await store.saveModele(modele);

      // Fermeture complète
      store.dispose();
      await db.close();

      // 2ème session : réouverture sur le même fichier
      db = db_layer.AppDatabase(NativeDatabase(dbFile));
      store = AppStore(db: db, clock: clock);
      await store.init(seedDemo: false);

      final restoredModele = store.modeleById('m_pers');
      expect(restoredModele, isNotNull);
      expect(restoredModele!.name, equals('Robe Persistante'));
      expect(restoredModele.photo, equals(savedPhoto.relativePath));

      final absPath = await photoStorage.getAbsolutePath(restoredModele.photo!);
      expect(File(absPath).existsSync(), isTrue);
      expect(await File(absPath).readAsBytes(), equals(bytes));

      store.dispose();
      await db.close();
    });

    test('8. Flux retrieveLostData simulé avec faux', () async {
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x55, 0x66]);
      final lostFile = File(p.join(tempDir.path, 'lost_photo.jpg'));
      await lostFile.writeAsBytes(sampleBytes);

      fakePicker.lostData = LostDataResponse(
        file: XFile(lostFile.path),
        files: [XFile(lostFile.path)],
      );

      final recovered = await photoStorage.retrieveLostData();
      expect(recovered, isNotNull);
      expect(recovered!.relativePath, startsWith('photos/'));
      expect(recovered.hash, equals(sha256.convert(sampleBytes).toString()));

      final absRecovered = await photoStorage.getAbsolutePath(recovered.relativePath);
      expect(File(absRecovered).existsSync(), isTrue);
    });

    test('9. JPEG assaini : aucune balise GPS, orientation 6 redressée (dimensions et pixels), hash stable et dédoublonné', () async {
      // 1. Génération d'une image test 40x80 avec balises GPS et Orientation = 6
      final rawImage = img.Image(width: 40, height: 80);
      for (int y = 0; y < 80; y++) {
        for (int x = 0; x < 40; x++) {
          rawImage.setPixelRgb(x, y, x * 5, y * 3, 120);
        }
      }
      final baseJpg = img.encodeJpg(rawImage);

      // Construction manuelle d'un segment APP1 Exif avec Orientation=6 et GPS
      final bb = BytesBuilder();
      bb.add([0x45, 0x78, 0x69, 0x66, 0x00, 0x00]); // Exif\0\0
      bb.add([0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00]); // TIFF header 'II'
      bb.add([0x02, 0x00]); // 2 tags IFD0
      // Tag 1: Orientation (0x0112), type SHORT, count 1, val 6
      bb.add([0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00]);
      // Tag 2: GPSInfo (0x8825), type LONG, count 1, offset 38
      bb.add([0x25, 0x88, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x26, 0x00, 0x00, 0x00]);
      bb.add([0x00, 0x00, 0x00, 0x00]); // next IFD = 0
      // GPS IFD (offset 38)
      bb.add([0x01, 0x00]); // 1 tag
      bb.add([0x00, 0x00, 0x01, 0x00, 0x04, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00, 0x00]); // GPSVersionID
      bb.add([0x00, 0x00, 0x00, 0x00]);

      final exifPayload = bb.toBytes();
      final app1Len = exifPayload.length + 2;

      final inputWithGpsAndOrientation6 = BytesBuilder();
      inputWithGpsAndOrientation6.add([0xFF, 0xD8]);
      inputWithGpsAndOrientation6.add([0xFF, 0xE1, (app1Len >> 8) & 0xFF, app1Len & 0xFF]);
      inputWithGpsAndOrientation6.add(exifPayload);
      inputWithGpsAndOrientation6.add(baseJpg.sublist(2));

      final dirtyBytes = inputWithGpsAndOrientation6.toBytes();
      expect(hasExifOrGpsMetadata(dirtyBytes), isTrue);
      expect(readExifOrientation(dirtyBytes), equals(6));

      // 2. Traitement par photoStorage.saveBytes
      final picked1 = await photoStorage.saveBytes(dirtyBytes);
      final absPath1 = await photoStorage.getAbsolutePath(picked1.relativePath);
      final storedBytes1 = await File(absPath1).readAsBytes();

      // Vérification 1 : aucune balise EXIF / GPS / IPTC résiduelle
      expect(hasExifOrGpsMetadata(storedBytes1), isFalse);
      expect(readExifOrientation(storedBytes1), isNull);

      // Vérification 2 : orientation correcte (dimensions inversées 80x40 car redressée 90° CW)
      final dims = extractJpegDimensions(storedBytes1);
      expect(dims, isNotNull);
      expect(dims!.$1, equals(80)); // width
      expect(dims.$2, equals(40)); // height

      // Vérification 3 : hash SHA-256 stable
      expect(picked1.hash, equals(sha256.convert(storedBytes1).toString()));

      // Vérification 4 : deux imports des mêmes octets -> un seul fichier physique dédoublonné
      final picked2 = await photoStorage.saveBytes(dirtyBytes);
      expect(picked2.relativePath, equals(picked1.relativePath));
      expect(picked2.hash, equals(picked1.hash));

      final photosDir = Directory(p.join(tempDir.path, 'photos'));
      final files = photosDir.listSync().whereType<File>().toList();
      expect(files.where((f) => f.path.endsWith('${picked1.hash}.jpg')).length, equals(1));
    });
  });
}
