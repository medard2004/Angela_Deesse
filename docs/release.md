# Procédure de Release & Signature Android

Ce document décrit la configuration de signature et la procédure de compilation pour les versions de production (Release) de l'application **Angela Déesse**.

---

## 1. Génération de la clé de signature privée (Keystore)

Pour signer l'application pour Android en vue d'une installation définitive sur l'appareil de l'atelier, générez une clé privée RSA 4096 bits à l'aide de l'outil `keytool` (inclus avec le JDK) :

```bash
keytool -genkey -v -keystore android/angela-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias angela-release
```

Renseignez un mot de passe robuste et notez-le soigneusement.

> [!CAUTION]
> **Sauvegarde vitale hors du dépôt Git** :
> La clé de signature (`angela-release.jks`) et son mot de passe doivent être sauvegardés hors du dépôt Git en **au moins deux endroits physiques distincts** (clé USB sécurisée, gestionnaire de mots de passe de l'atelier, coffre-fort numérique).
> **Si cette clé est perdue, Android refusera toute mise à jour de l'application existante sur le téléphone de l'atelier sans désinstaller l'ancienne version et perdre les données locales.**

---

## 2. Configuration locale (`android/key.properties`)

Créez le fichier `android/key.properties` (ce fichier est exclu par `.gitignore` et ne doit **jamais** être committé) :

```properties
storePassword=VOTRE_MOT_DE_PASSE_KEYSTORE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=angela-release
storeFile=angela-release.jks
```

*Remarque : si `key.properties` est absent, Gradle utilisera automatiquement la clé de signature debug par défaut avec un message explicite dans la console de build.*

---

## 3. Commande de compilation APK Release

Pour compiler l'APK de production optimisé et minifié par R8 / ProGuard :

```bash
flutter build apk --release
```

L'APK signé sera généré à l'emplacement :
`build/app/outputs/flutter-apk/app-release.apk`

Pour installer directement l'APK de production sur un téléphone Android connecté en USB (mode débogage USB activé) :

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. Règles R8 / ProGuard

L'application utilise :
- `sqlite3` et `drift` : code natif C et binding FFI préservés.
- `flutter_secure_storage` : classes Android Keystore et sérialisation sécurisée.
- `cryptography` : primitives cryptographiques.

Si des classes venaient à être tronquées par R8, des règles spécifiques peuvent être ajoutées dans `android/app/proguard-rules.pro`.

---

## 5. Icônes d'application et de notifications

### Icône de notification (drawable monochrome)
Android exige une petite icône monochrome (blanc sur fond transparent) pour les notifications système afin d'éviter l'affichage d'un carré blanc plein.
Le drawable vectoriel `ic_stat_notification.xml` est configuré dans `android/app/src/main/res/drawable/ic_stat_notification.xml` avec la couleur d'accent `Pal.cobalt` (`#002B49`).

### Remplacement de l'icône de l'application (Logo officiel)
Actuellement, l'icône d'application utilise le logo par défaut. Pour installer le logo officiel dès qu'il sera disponible :
1. Placer le fichier source (PNG 1024x1024) dans `assets/brand/logo.png`.
2. Utiliser le paquet `flutter_launcher_icons` en ajoutant la configuration dans `pubspec.yaml` :
   ```yaml
   flutter_launcher_icons:
     android: "launcher_icon"
     ios: true
     image_path: "assets/brand/logo.png"
     adaptive_icon_background: "#002B49"
     adaptive_icon_foreground: "assets/brand/logo_foreground.png"
   ```
3. Exécuter `dart run flutter_launcher_icons`.
4. Ne jamais modifier l'identifiant technique `com.digitalvision.angela_dress` (qui définit l'identité Android de l'application).

