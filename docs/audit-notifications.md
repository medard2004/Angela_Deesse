# Audit Exhaustif du Système de Notifications et d'Alarmes — Angela Déesse

> **Date de l'état des lieux** : 6 novembre 2026  
> **Mode** : LECTURE SEULE (aucune modification de code, aucun ajout de paquet, aucun commit)  
> **Branche Git** : `feat/notifications` — Copie de travail propre (`git status` : rien à valider)  
> **Référence des règles projet** : `CLAUDE.md` (tag gelé : `schema-v1-frozen`)

---

## SECTION 1 : Architecture réelle de l'alarme

### 1.1 Planificateur et API exacte
* **Planificateur réel** : Plugin Flutter `flutter_local_notifications` via l'instance `FlutterLocalNotificationsPlugin` ([lib/data/services/system_reminder_service.dart#L78](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L78)).
* **API exacte appelée en Dart** : `plugin.zonedSchedule(...)` ([lib/data/services/system_reminder_service.dart#L283-L291](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L283-L291), [#L449-L457](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L449-L457), [#L55-L63](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L55-L63)).
* **Mode Android exact (`androidScheduleMode`)** :
  * Dans `rescheduleAll` : `AndroidScheduleMode.exactAllowWhileIdle` si `canScheduleExactAlarms()` est vrai, sinon repli sur `AndroidScheduleMode.inexactAllowWhileIdle` ([lib/data/services/system_reminder_service.dart#L289-L290](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L289-L290)).
  * Dans le report en arrière-plan (`snooze`) : `AndroidScheduleMode.exactAllowWhileIdle` ([lib/data/services/system_reminder_service.dart#L61](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L61)).
  * Dans le banc de test `scheduleRingerTest` : `AndroidScheduleMode.exactAllowWhileIdle` ou `inexactAllowWhileIdle` ([lib/data/services/system_reminder_service.dart#L443-L445](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L443-L445)).
* **API Android native sous-jacente** : Le plugin invoque `AlarmManager.setExactAndAllowWhileIdle()` ou `setAndAllowWhileIdle()`. L'API `AlarmManager.setAlarmClock()` n'est pas utilisée.

---

### 1.2 Déclenchement Son / Vibration et cycle de vie écran éteint
* **Qui fait sonner et vibrer ?**
  * **Cas écran éteint / app tuée** : C'est le gestionnaire de notifications du système Android (`NotificationManager`) qui joue le son configuré sur le canal `alarmes_douces_v3` (`sound: RawResourceAndroidNotificationSound('gentle_alarm')`, [lib/data/services/system_reminder_service.dart#L116](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L116)) et active le vibreur système.
  * **Cas app ouverte au premier plan** : C'est l'écran Flutter [AlarmRingingScreen](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L75) via `AlarmSoundService.startAlarm()` qui pilote un `MediaPlayer` natif Android dans [MainActivity.kt#L24-L42](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/kotlin/com/digitalvision/angela_dress/MainActivity.kt#L24-L42), combiné au timer de vibration Dart `HapticFeedback.vibrate()` ([lib/screens/alarm_ringing_screen.dart#L88-L92](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L88-L92)).
* **Déroulé chronologique exact (téléphone verrouillé, écran éteint, app tuée)** :
  1. `AlarmManager` système réveille le receveur `ScheduledNotificationReceiver` ([android/app/src/main/AndroidManifest.xml#L40-L42](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/AndroidManifest.xml#L40-L42)).
  2. Le plugin construit et affiche la notification avec `fullScreenIntent: true` ([lib/data/services/system_reminder_service.dart#L115](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L115)).
  3. Le système Android émet la sonnerie `gentle_alarm.ogg` et vibre.
  4. Android lance l'intent plein écran ciblant `MainActivity` (grâce à `android:showWhenLocked="true"` et `android:turnScreenOn="true"`, [android/app/src/main/AndroidManifest.xml#L23-L24](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/AndroidManifest.xml#L23-L24)).
  5. Le processus de l'application démarre à froid : `lib/main.dart` -> `runApp(AngelaApp)` -> `SplashScreen` ([lib/screens/splash_screen.dart#L44](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/splash_screen.dart#L44)).
  6. **Constat critique** : `getNotificationAppLaunchDetails()` est **ABSENT** du code de démarrage (`main.dart` et `app.dart`). Par conséquent, l'événement plein écran ne route pas automatiquement vers `AlarmRingingScreen` au lancement à froid. L'application reste sur `SplashScreen` puis bascule sur `LockScreen` (verrou PIN).
  7. **Boucle audio `MediaPlayer`** : Elle ne commence **JAMAIS** dans ce cas, car elle n'est déclenchée que dans `_AlarmRingingScreenState.initState()` ([lib/screens/alarm_ringing_screen.dart#L75](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L75)).
  8. **La sonnerie démarre-t-elle sans que l'écran Flutter s'ouvre ?** : **OUI**, le son de la notification Android est émis par le système d'exploitation, mais il s'arrête dès que la piste de 5 secondes se termine (ou s'arrête si l'OS ne boucle pas le son de notification).

---

### 1.3 Nature exacte de AlarmSoundService
* **Fichier Dart** : [lib/data/services/alarm_sound_service.dart](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alarm_sound_service.dart#L5-L23).
* **Déclaration au manifeste Android** : **ABSENT**. Ce n'est pas un composant Android (`android.app.Service`), mais une simple classe wrapper Dart autour d'un `MethodChannel` (`com.digitalvision.angela_dress/alarm_sound`).
* **Type de service de premier plan (`foregroundServiceType`)** : **ABSENT**. Aucun service Android de premier plan n'est déclaré dans `AndroidManifest.xml`.
* **Notification associée** : **ABSENT**.
* **Code réel qui joue le son** : Un `android.media.MediaPlayer` instancié directement dans l'activité [MainActivity.kt#L13](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/kotlin/com/digitalvision/angela_dress/MainActivity.kt#L13) et piloté via le `MethodChannel` ([MainActivity.kt#L22-L42](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/kotlin/com/digitalvision/angela_dress/MainActivity.kt#L22-L42)).

---

### 1.4 Mécanisme plein écran et composants du manifeste
* **Attributs et permissions** :
  * `fullScreenIntent: true` dans `AndroidNotificationDetails` ([lib/data/services/system_reminder_service.dart#L115](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L115)).
  * `android:showWhenLocked="true"` et `android:turnScreenOn="true"` sur `MainActivity` ([android/app/src/main/AndroidManifest.xml#L23-L24](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/AndroidManifest.xml#L23-L24)).
* **Liste COMPLÈTE des `<uses-permission>` dans `AndroidManifest.xml`** ([L2-L7](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/AndroidManifest.xml#L2-L7)) :
  1. `android.permission.RECEIVE_BOOT_COMPLETED`
  2. `android.permission.VIBRATE`
  3. `android.permission.POST_NOTIFICATIONS`
  4. `android.permission.USE_EXACT_ALARM`
  5. `android.permission.SCHEDULE_EXACT_ALARM` (avec `android:maxSdkVersion="32"`)
  6. `android.permission.USE_FULL_SCREEN_INTENT`
* **Liste COMPLÈTE des services (`<service>`) dans `AndroidManifest.xml`** : **AUCUN** (`absent`).
* **Liste COMPLÈTE des receveurs (`<receiver>`) dans `AndroidManifest.xml`** ([L40-L55](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/AndroidManifest.xml#L40-L55)) :
  1. `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver`
  2. `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver`
  3. `com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver`

---

### 1.5 Vérification de canUseFullScreenIntent (Android 14+)
* **Vérification `canUseFullScreenIntent`** : **ABSENT** du code (aucune recherche dans `lib/` ni `android/` ne référence cette permission dynamique).
* **Si l'autorisation est refusée par l'OS** : Android 14+ rétrograde automatiquement le plein écran en notification flottante (Heads-Up). Le son système de la notification retentit, mais l'écran `AlarmRingingScreen` ne s'ouvrant pas, le lecteur en boucle `MediaPlayer` ne démarre pas.

---

### 1.6 Comportement téléphone déverrouillé avec une autre application ouverte
* L'application Angela Déesse n'étant pas au premier plan, l'alarme est reçue par le système Android.
* **Ce que voit l'utilisatrice** : Une notification flottante (Heads-Up Notification / bannière système en haut de l'écran) affichant le titre, le corps et les deux boutons d'action **« Arrêter »** et **« Reporter 10 min »**. Elle **ne voit pas** l'écran plein écran Flutter `AlarmRingingScreen`.
* **Ce qu'elle entend** : Le son système de notification (`gentle_alarm.ogg`) joué une fois par le système Android.

---

### 1.7 Boutons d'action natifs (Arrêter / Reporter)
* **Traitement natif ou moteur Flutter ?** : Ils sont traités par un **Isolate Dart d'arrière-plan** lancé par `ActionBroadcastReceiver` via la fonction annotée `@pragma('vm:entry-point') void notificationActionBackgroundHandler(...)` ([lib/data/services/system_reminder_service.dart#L17-L69](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L17-L69)). Ce n'est donc pas du Kotlin natif pur, mais un Isolate Flutter headless d'arrière-plan.
* **Action « Arrêter » (`kActionDone`)** : Exécute `await plugin.cancel(id: notificationId)` ([lib/data/services/system_reminder_service.dart#L29](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L29)). Supprime la notification de l'écran.
* **Action « Reporter 10 min » (`kActionSnooze`)** :
  1. Annule la notification actuelle ([lib/data/services/system_reminder_service.dart#L35](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L35)).
  2. Parse le payload JSON ([lib/data/services/system_reminder_service.dart#L39](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L39)).
  3. Calcule un identifiant dédié sur masque 31-bit : `snoozeId = (notificationId | 0x40000000) & 0x7FFFFFFF` ([lib/data/services/system_reminder_service.dart#L42](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L42)).
  4. Ajoute 10 minutes : `snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10))` ([lib/data/services/system_reminder_service.dart#L45](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L45)).
  5. Replanifie via `plugin.zonedSchedule(..., scheduledDate: snoozeTime, androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle)` ([lib/data/services/system_reminder_service.dart#L55-L63](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L55-L63)).

---

### 1.8 Replanification après redémarrage du téléphone
* **Qui replanifie ?** : Le composant Android `ScheduledNotificationBootReceiver` de `flutter_local_notifications` ([android/app/src/main/AndroidManifest.xml#L45-L52](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/AndroidManifest.xml#L45-L52)) qui restaure les alarmes mémorisées dans les préférences du plugin lors du broadcast `BOOT_COMPLETED`.
* **Sans ouvrir l'application, sonnent-elles encore ?** : **OUI**, pour les alarmes dont l'échéance future était déjà programmée dans le plugin. En revanche, aucune nouvelle alarme n'est recalculée depuis SQLite tant que l'artisan n'ouvre pas l'application (pas de WorkManager ni de service autonome au boot dans Angela Déesse).

---

### 1.9 Arrêt automatique de 60 secondes
* **Où est la minuterie ?** :
  1. Côté Android OS : `timeoutAfter: 60000` (60 secondes) dans les détails de notification ([lib/data/services/system_reminder_service.dart#L119](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L119)).
  2. Côté écran Flutter : Minuterie Dart `Timer.periodic` de 1 seconde dans `_AlarmRingingScreenState` ([lib/screens/alarm_ringing_screen.dart#L74-L83](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L74-L83)).
* **Que devient l'alarme à expiration ?** :
  * `_handleStop(timeout: true)` coupe le son via `AlarmSoundService.stopAlarm()`, annule la notification OS via `plugin.cancel()`, et ferme l'écran avec `Navigator.pop()` ([lib/screens/alarm_ringing_screen.dart#L104-L120](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L104-L120)).
* **Laisse-t-elle une trace ?** : **AUCUNE TRACE** (`absent`). Aucun historique, aucun statut "manqué" n'est enregistré en base SQLite ou SharedPreferences.

---

### 1.10 Gestion de la concurrence et alarmes simultanées
* **Plusieurs alarmes à la même minute** : Fusionnées en amont en une seule alarme groupée par `AlertEngine.groupedPlannedReminders` ([lib/data/services/alert_engine.dart#L266-L319](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L266-L319)), portant le titre « n rappels » et listant jusqu'à 4 lignes.
* **Alarme qui arrive pendant qu'une autre sonne** :
  * L'écran Flutter maintient un drapeau statique `AlarmRingingScreen.isAlarmShowing` ([lib/screens/alarm_ringing_screen.dart#L30](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L30)).
  * Dans `lib/app.dart#L43` : `if (!AlarmRingingScreen.isAlarmShowing) { push(...); }`.
  * **Comportement réel** : La seconde alarme est **ignorée visuellement par Flutter** pour éviter d'empiler deux écrans de réveil. La notification système correspondante apparaît dans la barre d'état.

---

### 1.11 Fichier sonore gentle_alarm
* **Origine et licence** : Synthétisé localement par script interne Python générant des sinusoïdes harmoniques (C5, E5, G5, B5, C6) via `math.sin` et compressé via `ffmpeg -c:a libvorbis` (commit `cbf21da`). Zéro ressource externe, 100 % libre de droits.
* **Format** : Ogg Vorbis mono, 44 100 Hz, débit ~86 kbps ([android/app/src/main/res/raw/gentle_alarm.ogg](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/res/raw/gentle_alarm.ogg)).
* **Durée** : Exactement 5,00 secondes.
* **Boucle** :
  * Dans `MainActivity.kt#L39` : `mediaPlayer.isLooping = true` (boucle continue tant que l'écran d'alarme est visible).
  * Dans la notification Android : `additionalFlags: Int32List.fromList([4])` (FLAG_INSISTENT, [lib/data/services/system_reminder_service.dart#L118](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L118)).
* **Flux audio** : `AudioAttributes.USAGE_ALARM` / `STREAM_ALARM` ([MainActivity.kt#L27](file:///home/othnelio/Angela/Angela_Deesse/android/app/src/main/kotlin/com/digitalvision/angela_dress/MainActivity.kt#L27) et [system_reminder_service.dart#L113](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L113)).
* **Comportement si volume des alarmes à 0** : Le son est inaudible (muet), mais les vibrations tactiles et l'écran visuel fonctionnent.

---

## SECTION 2 : Contenu et confidentialité

### 2.1 Textes affichés et données visibles
* **Textes générés par le moteur** :
  * Titre : `AlertStrings.fittingToday` (« Essayage aujourd'hui à 15h30 »), `AlertStrings.deliveryToday` (« Livraison aujourd'hui »), etc. ([lib/data/utils/alert_strings.dart#L7-L27](file:///home/othnelio/Angela/Angela_Deesse/lib/data/utils/alert_strings.dart#L7-L27)).
  * Corps : `AlertStrings.orderBody` (`'$name · $title'`) ([lib/data/utils/alert_strings.dart#L29-L33](file:///home/othnelio/Angela/Angela_Deesse/lib/data/utils/alert_strings.dart#L29-L33)).
* **Données sur l'écran d'alarme (`AlarmRingingScreen`)** :
  * **Nom de client** : **OUI, PRÉSENT** dans `body` affiché au centre de l'écran ([lib/screens/alarm_ringing_screen.dart#L203](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L203)).
  * **Titre de commande** : **OUI, PRÉSENT** dans `body` ([lib/screens/alarm_ringing_screen.dart#L203](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L203)).
  * **Montant d'argent** : **NON, STRICTEMENT AUCUN MONTANT** (exclu formellement dans `AlertStrings.orderBody`).
* **Affichage sur écran verrouillé (version publique)** :
  * Les notifications sont déclarées avec `visibility: NotificationVisibility.private` ([lib/data/services/system_reminder_service.dart#L122](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L122)).
  * Sur écran verrouillé, Android affiche la mention générique « Contenu masqué » selon les réglages système de l'appareil. Aucune notification publique alternative (`publicVersion`) n'est configurée dans le code.

---

### 2.2 Verrou PIN et écran d'alarme
* **L'écran d'alarme passe-t-il au-dessus du verrou PIN ?** :
  * Si l'application est déjà en mémoire et déverrouillée : `AlarmRingingScreen` est poussé sur le `Navigator` principal et s'affiche au premier plan ([lib/app.dart#L44-L53](file:///home/othnelio/Angela/Angela_Deesse/lib/app.dart#L44-L53)).
  * Si l'application démarre à froid : `MainActivity` démarre sur `SplashScreen` puis `LockScreen`. `AlarmRingingScreen` ne s'ouvre pas automatiquement au-dessus du verrou PIN au lancement à froid.
* **Arrêter et Reporter exigent-ils le PIN ?** :
  * **NON**. Que ce soit depuis les boutons d'action de la notification système (`action_done`, `action_snooze` dans [system_reminder_service.dart#L27-L34](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L27-L34)) ou depuis l'écran `AlarmRingingScreen` ([lib/screens/alarm_ringing_screen.dart#L104-L139](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L104-L139)), aucune saisie de code PIN n'est requise.
* **État de l'app après démarrage à froid et arrêt de l'alarme** :
  * L'application reste **verrouillée**. `AppLockManager` ([lib/app.dart#L89-L96](file:///home/othnelio/Angela/Angela_Deesse/lib/app.dart#L89-L96)) maintient `LockScreen` actif tant que le code PIN valide n'est pas saisi.

---

### 2.3 Navigation depuis la notification vers NotificationsScreen
* Quand la notification est touchée :
  1. `onDidReceiveNotificationResponse` est déclenché et positionne `NotificationCenterService.pendingOpenNotifications = true` ([lib/data/services/system_reminder_service.dart#L193](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L193)).
  2. L'application affiche `LockScreen`.
  3. L'artisan tape son code PIN avec succès ; `LockScreen` est dépilé (`Navigator.pop()`).
  4. `AppShell` détecte le drapeau dans `didChangeDependencies()` ([lib/shell/app_shell.dart#L60-L66](file:///home/othnelio/Angela/Angela_Deesse/lib/shell/app_shell.dart#L60-L66)), remet `pendingOpenNotifications` à `false` et active l'onglet `Section.notifications`.

---

## SECTION 3 : Bandeau in-app et doublons

### 3.1 Détection du premier plan et déclencheur du bandeau
* **Détection du premier plan** : Via `WidgetsBinding.instance.lifecycleState` ([lib/data/services/system_reminder_service.dart#L389-L391](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L389-L391)) vérifiant `state == AppLifecycleState.resumed`.
* **Vérification de déverrouillage** : **ABSENT**. Le code ne vérifie pas si l'app est déverrouillée (il n'interroge pas `AppLockManager`).
* **Déclencheur du bandeau** :
  1. Une minuterie Dart `Timer` planifiée au premier plan ([lib/data/services/system_reminder_service.dart#L461](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L461)).
  2. À expiration, `_triggerInAppForegroundAlert` annule la notification OS via `plugin.cancel` ([lib/data/services/system_reminder_service.dart#L396](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L396)) et émet sur le flux Dart `inAppEventStream` ([lib/data/services/system_reminder_service.dart#L411](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L411)).
  3. `AngelaApp` écoute ce flux et invoque `InAppNotificationBanner.show(...)` ([lib/app.dart#L59](file:///home/othnelio/Angela/Angela_Deesse/lib/app.dart#L59)).

---

### 3.2 Nombre de signaux reçus par l'utilisatrice
* **(a) Catégorie « alarme », app ouverte** :
  * **2 signaux simultanés (DOUBLON)** :
    1. Signal système : `plugin.show(...)` est appelé ([lib/data/services/system_reminder_service.dart#L401](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L401)), générant une notification Android dans la barre d'état avec son push.
    2. Signal in-app : `AlarmRingingScreen` s'ouvre en plein écran ([lib/app.dart#L44-L53](file:///home/othnelio/Angela/Angela_Deesse/lib/app.dart#L44-L53)) et lance la boucle audio native `MediaPlayer` + vibrations.
* **(b) Catégorie « notification », app ouverte** :
  * **1 seul signal (SANS DOUBLON)** : La notification push OS est expressément annulée via `plugin.cancel(id: id)` ([lib/data/services/system_reminder_service.dart#L396](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L396)), et seul le bandeau in-app descend en haut de l'écran.
* **(c) App fermée** :
  * **1 signal** : La notification système Android programmée par `zonedSchedule`.
* **(d) Téléphone verrouillé** :
  * **1 signal** : La notification système Android programmée par `zonedSchedule` (tentative de plein écran réveil si catégorie alarme, notification privée masquée si catégorie notification).

---

### 3.3 Résilience aux plantages
* Les notifications planifiées à long terme résident dans le système Android via `plugin.zonedSchedule` ([lib/data/services/system_reminder_service.dart#L283](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L283)).
* Si l'application plante ou est tuée en arrière-plan, les alarmes enregistrées auprès du système Android **ne sont pas perdues** car `plugin.cancel` n'est invoqué qu'au moment précis de l'expiration du timer au premier plan.

---

## SECTION 4 : Catégories, réglages et valeurs par défaut

### 4.1 Catégories réelles du moteur
* **Familles réelles déclarées dans l'enum `AlertFamily`** ([lib/data/services/alert_engine.dart#L6-L11](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L6-L11)) :
  1. `AlertFamily.delivery` (Livraisons)
  2. `AlertFamily.fitting` (Essayages)
  3. `AlertFamily.apprenticeDue` (Échéances d'écolage des apprentis)
  4. `AlertFamily.pendingBalance` (Soldes en attente des commandes prêtes)
* **Existence des termes « paiement, validation, tâche de production »** :
  * « paiement » : n'existe pas en tant que catégorie sous ce nom (correspond soit à `pendingBalance`, soit à `apprenticeDue`).
  * « validation » : **TOTALEMENT ABSENT** du code.
  * « tâche de production » : **TOTALEMENT ABSENT** du code.

---

### 4.2 Stockage des modes, clés exactes et valeurs par défaut
* **Support de stockage** : Table Drift `settings` (`id = key`, `value = 'alarm' | 'notification' | 'none'`) gérée par `SettingsRepository` ([lib/data/repositories/settings_repository.dart#L15-L45](file:///home/othnelio/Angela/Angela_Deesse/lib/data/repositories/settings_repository.dart#L15-L45)).
* **Clés et valeurs par défaut de chaque catégorie** :
  1. `notif_delivery` : `kDefaultModeDelivery = ReminderMode.alarm` ([lib/data/repositories/settings_repository.dart#L42](file:///home/othnelio/Angela/Angela_Deesse/lib/data/repositories/settings_repository.dart#L42)).
  2. `notif_fitting` : `kDefaultModeFitting = ReminderMode.alarm` ([lib/data/repositories/settings_repository.dart#L43](file:///home/othnelio/Angela/Angela_Deesse/lib/data/repositories/settings_repository.dart#L43)).
  3. `notif_payments` : `kDefaultModePayments = ReminderMode.notification` ([lib/data/repositories/settings_repository.dart#L44](file:///home/othnelio/Angela/Angela_Deesse/lib/data/repositories/settings_repository.dart#L44)).
  4. `notif_late` : `kDefaultModeLate = ReminderMode.notification` ([lib/data/repositories/settings_repository.dart#L45](file:///home/othnelio/Angela/Angela_Deesse/lib/data/repositories/settings_repository.dart#L45)).
* **L'échéance d'apprenti est-elle en alarme par défaut ?** :
  * **NON, CONTRADICTOIRE** : Dans [lib/data/services/alert_engine.dart#L455](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L455), les échéances d'apprentis utilisent le mode `paymentsMode` (`notif_payments`), dont la valeur par défaut est `ReminderMode.notification`. Elles sont donc en **notification simple par défaut**, et non en alarme.

---

### 4.3 Remplacement des anciens interrupteurs
* Dans l'interface [SettingsScreen](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/settings_screen.dart#L291-L330), les interrupteurs binaires ont été remplacés par des tuiles de sélection modale à 3 états (`Alarme`, `Notification`, `Désactivé`).
* Dans [lib/data/store.dart#L144-L147](file:///home/othnelio/Angela/Angela_Deesse/lib/data/store.dart#L144-L147), les getters booléens historiques sont conservés comme façades (`notifDelivery => deliveryMode != ReminderMode.none`).

---

### 4.4 Règles exactes de planification et invariants
* `plannedReminders` existe dans [lib/data/services/alert_engine.dart#L438-L593](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L438-L593).
* **Heures précises de planification** :
  * **Essayages** : Veille à **18:00** ([L478](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L478)) ; Jour J : **1 h avant** si heure renseignée ([L495](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L495)), sinon à **08:00** ([L496](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L496)).
  * **Livraisons** : 2 jours avant à **18:00** ([L520](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L520)) ; Veille à **18:00** ([L532](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L532)) ; Jour J à **08:00** ([L544](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L544)).
  * **Échéances d'apprentis** : 7 jours avant à **08:00** ([L560](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L560)) ; Veille à **18:00** ([L569](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L569)) ; Jour J à **08:00** ([L578](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L578)).
* **Fenêtre temporelle** : `maxWindowDays = 45` jours ([L451](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L451)).
* **Plafond maximal** : `maxReminders = 120` ([L597](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L597)).
* **Test de l'invariant** : Validé dans [test/services/alert_engine_test.dart#L203-L241](file:///home/othnelio/Angela/Angela_Deesse/test/services/alert_engine_test.dart#L203-L241) (« tout rappel planifié à un instant T correspond à une alerte active dans currentAlerts(T) »).

---

### 4.5 Clés stables et persistance des alertes d'un jour sur l'autre
* **Structure des clés stables** : `famille:etape:idEntite:jourCible`.
  * Livraisons : `jourCible` = `order.deliveryDate` formaté YYYY-MM-DD ([lib/data/services/alert_engine.dart#L244](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L244)).
  * Soldes dus : `jourCible` = `order.deliveryDate` ([lib/data/services/alert_engine.dart#L324](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L324)).
  * Échéances d'apprentis : `jourCible` = `apprentice.nextDue` ([lib/data/services/alert_engine.dart#L350](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L350)).
  * Essayages : `jourCible` = `order.fittingDate` ([lib/data/services/alert_engine.dart#L198](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L198)).
* **Les alertes persistantes gardent-elles la MÊME clé ?** : **OUI**. Tant qu'une commande reste en retard, sa clé `livraison:retard:${order.id}:$dDayKey` ne varie pas car `$dDayKey` est ancré sur la date promise et non sur la date du jour.
* **Une alerte « en retard » déjà vue redevient-elle non vue le lendemain ?** : **NON**. Comme la clé ne change pas le lendemain, l'état lu persisté dans `SharedPreferences` sous cette clé demeure actif. L'alerte reste marquée comme **vue**.

---

### 4.6 Règles d'alertes par rapport aux métriques d'accueil
* **Les chiffres de la carte d'accueil ont-ils changé ?** : **NON**. Les métriques d'activité de l'accueil ([lib/screens/home_screen.dart#L120-L139](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/home_screen.dart#L120-L139)) lisent directement `activeOrders.length`, `week.length` et `punctualityRate`.
* **Liste des priorités de l'accueil** : Elle filtre `currentAlerts` pour ne retenir que `today`, `late` et `pendingBalance` ([lib/screens/home_screen.dart#L73-L78](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/home_screen.dart#L73-L78)).
* Les alertes « dans 2 jours » et « approche <= 7 jours » ont une sévérité `upcoming` et sont donc **exclues de la carte des priorités de l'accueil**. Elles n'apparaissent que dans `NotificationsScreen`.
* L'alerte « solde dû d'une commande prête » (`pendingBalance`) est une règle introduite avec `AlertEngine` et figure bien dans les priorités de l'accueil.

---

## SECTION 5 : Page de notifications et état

### 5.1 Contenu de NotificationsScreen et persistance
* **Sources de données** : Appel dynamique à `AlertEngine.currentAlerts(now)` ([lib/screens/notifications_screen.dart#L91-L98](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/notifications_screen.dart#L91-L98)) calculé sur les commandes actives et apprentis d'`AppStore`.
* **Tri et sections** : Liste séquentielle non subdivisée en sections, suivant l'ordre d'évaluation du moteur (essayages, puis livraisons, puis soldes, puis apprentis).
* **Historique des alarmes qui ont sonné** : **TOTALEMENT ABSENT** (`absent`). Aucun journal ni historique d'alarmes passées n'est conservé.
* **Stockage de l'état vu / non vu** : Dans `SharedPreferences` via `NotificationCenterService` sous la clé `'seen_alerts'` ([lib/data/services/notification_center_service.dart#L58-L65](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/notification_center_service.dart#L58-L65)), hors base SQLite Drift.

---

### 5.2 Conséquence de l'arrêt, du report ou de l'expiration d'une alarme
* **Dans la page `NotificationsScreen`** : L'alerte **ne change pas**. Elle reste visible tant que la commande n'est pas livrée ou le paiement enregistré dans SQLite.
* **Notification système** :
  * Arrêtée : annulée immédiatement par `plugin.cancel` ([system_reminder_service.dart#L29](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L29)).
  * Reportée : annulée puis replanifiée à +10 min ([system_reminder_service.dart#L35](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L35)).
  * Expirée : retirée par le timeout de 60s ([system_reminder_service.dart#L119](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L119)).

---

### 5.3 Câblage de pendingOpenNotifications
* **App en arrière-plan** : Câblé via `onDidReceiveNotificationResponse` ([system_reminder_service.dart#L193](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L193)) puis consommé par `AppShell` ([lib/shell/app_shell.dart#L60-L66](file:///home/othnelio/Angela/Angela_Deesse/lib/shell/app_shell.dart#L60-L66)) après déverrouillage PIN.
* **Lancement à froid** : **NON CÂBLÉ** (`absent`). `getNotificationAppLaunchDetails` n'étant pas consommé au démarrage, le clic lors d'un lancement à froid n'active pas `pendingOpenNotifications`.
* **Couverture par les tests** : Couvert par [test/widgets/post_pin_navigation_test.dart#L40-L80](file:///home/othnelio/Angela/Angela_Deesse/test/widgets/post_pin_navigation_test.dart#L40-L80).

---

### 5.4 Respect de disableAnimations
* **Pastille non-vue** : Dans [lib/screens/notifications_screen.dart#L240-L247](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/notifications_screen.dart#L240-L247), c'est un simple `Container` statique circulaire orange de 8x8 pixels (pas d'animation pulsante).
* **Respect de `MediaQuery.disableAnimations`** : **TOTALEMENT ABSENT** du projet (aucune occurrence de `disableAnimations` dans l'ensemble du répertoire `lib/`).

---

## SECTION 6 : Build, schéma et qualité

### 6.1 Intégrité du schéma Drift
* Commande exécutée : `git diff schema-v1-frozen -- lib/data/db/ drift_schemas/`
* **Résultat** : **AUCUNE DIFFÉRENCE (0 modification)**. Le schéma SQLite Drift est strictement identique au tag gelé `schema-v1-frozen`. Aucune table ni colonne n'a été ajoutée ou modifiée.

---

### 6.2 Compilation Release et Signature
* **Vérification de la compilation release** : `flutter build apk --release` a été testé avec succès dans l'environnement (R8 / shrinkResources passe sans erreur).
* **Signature** : Comme documenté dans `android/app/build.gradle.kts#L11-L20`, en l'absence du fichier `android/key.properties` (exclu par `.gitignore`), Gradle bascule automatiquement sur la clé de signature **debug** par défaut (`signingConfigs.getByName("debug")`).

---

### 6.3 Couverture des tests sur le code natif et le routage
* **Tests couvrant le code natif Kotlin (`MainActivity.kt`)** : **AUCUN** (`absent`). Aucun test unitaire ou instrumenté Android n'existe dans le dossier `android/`.
* **Tests de routage app / hors app** :
  * [test/screens/alarm_ringing_screen_test.dart](file:///home/othnelio/Angela/Angela_Deesse/test/screens/alarm_ringing_screen_test.dart) (affichage de l'écran avec un faux plugin).
  * [test/widgets/in_app_notification_banner_test.dart](file:///home/othnelio/Angela/Angela_Deesse/test/widgets/in_app_notification_banner_test.dart) (apparition et disparition du bandeau in-app).
  * [test/widgets/post_pin_navigation_test.dart](file:///home/othnelio/Angela/Angela_Deesse/test/widgets/post_pin_navigation_test.dart) (navigation post-PIN).
  * Le routage réel hors-app (réveil effectif de l'OS, `fullScreenIntent` natif) n'est couvert par aucun test automatisé de la suite Flutter.

---

### 6.4 Paquets ajoutés depuis schema-v1-frozen
* `git diff schema-v1-frozen -- pubspec.yaml` :
  1. `app_settings: ^9.0.1` : ouverture des réglages système (optimisation batterie).
  2. `device_info_plus: ^13.3.0` : détection du constructeur (Samsung, Xiaomi, Tecno).
  3. `flutter_local_notifications: ^22.3.3` : notifications locales et réveils système.
  4. `pdf: ^3.11.1` & `printing: ^5.13.2` : reçus thermiques locaux.
  5. `shared_preferences: ^2.5.6` : persistance des états vus/non-vus hors base SQLite.
  6. `timezone: ^0.11.2` : gestion des instants de planification locale.
* Hashes des derniers commits récents sur la branche :
  * `74ecc37` : fix(alarm): lecture native en boucle sur STREAM_ALARM et canal v3 pour sonnerie fiable
  * `cbf21da` : fix(notifications): sonnerie douce personnalisée, déclenchement immédiat de l'alarme plein écran et bandeau in-app au premier plan
  * `d483653` : feat(reminders): boutons de test rapide 10s et notification standard dans le guide
  * `d16e793` : feat(notifications): alarmes réveil plein écran, notifications in-app et personnalisation des modes

---

### 6.5 Tableau d'audit de la marque et provenance du logo
* **Provenance des logos** :
  * Les fichiers `assets/images/logo_mark.png` et `assets/images/logo_full.png` ainsi que `android/app/src/main/res/drawable-v21/splash_logo.png` proviennent du **premier commit initial du projet (`74afdf5`)**, déposé lors de l'initialisation du dépôt par l'utilisateur.
  * Aucun dossier `assets/brand/` n'existe dans le projet (`absent`).
* **Tableau exhaustif des occurrences de marque dans `lib/`** (16 occurrences trouvées) :

| Fichier | Ligne | Texte exact |
|---|---|---|
| `lib/core/app_brand.dart` | L1 | `/// Référence d'identité unique pour l'application Angela Déesse.` |
| `lib/core/app_brand.dart` | L9 | `static const String appName = 'Angela Déesse';` |
| `lib/core/app_brand.dart` | L13 | `static const String defaultAtelierName = 'Angela Déesse';` |
| `lib/core/theme.dart` | L4 | `/// Palette de l'application Angela Déesse : bleu cobalt + orange, encre marine...` |
| `lib/data/db/app_database.dart` | L187 | `final file = File(p.join(dbFolder.path, 'angela_deesse.sqlite'));` |
| `lib/data/services/receipt_pdf_generator.dart` | L74 | `creator: 'Angela Déesse',` |
| `lib/screens/apprentice_detail_screen.dart` | L35 | `itemDetail: 'Formation couture',` |
| `lib/screens/apprentice_screen.dart` | L86 | `itemDetail: 'Formation couture',` |
| `lib/screens/receipt_screen.dart` | L736 | `const _StampBadge({required this.text, this.atelierName = 'Angela Déesse'});` |
| `lib/screens/reminder_guide_screen.dart` | L405 | `'...pour Angela Déesse.'` |
| `lib/screens/reminder_guide_screen.dart` | L452 | `'2. Allez dans « Démarrage automatique » et activez Angela Déesse.\n'` |
| `lib/screens/reminder_guide_screen.dart` | L453 | `'3. Dans la liste des applications récentes, glissez Angela Déesse vers le bas...'` |
| `lib/screens/reminder_guide_screen.dart` | L486 | `'1. Ouvrez les Paramètres > Applications > Gérer les applications > Angela Déesse.\n'` |
| `lib/screens/reminder_guide_screen.dart` | L523 | `'3. Ajoutez Angela Déesse dans « Applications jamais en veille ».'` |
| `lib/screens/reminder_guide_screen.dart` | L536 | `'...autoriser Angela Déesse à s\'exécuter en arrière-plan.'` |
| `lib/screens/splash_screen.dart` | L228 | `final targetOffset = computeAppBarLogoCenter(context, label: 'Angela Déesse');` |

---

## SECTION 7 : Écarts par rapport aux décisions (D1 à D10)

| Décision | Évaluation | Preuve et ligne de code |
|---|---|---|
| **D1** : Push = notification système locale, sans serveur, sans FCM, sans réseau | **CONFORME** | [lib/data/services/system_reminder_service.dart#L78](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L78) utilise uniquement `flutter_local_notifications` en local. |
| **D2** : Alarme sur téléphone verrouillé / écran éteint : plein écran, sonnerie et vibration en boucle ; son indépendant de Flutter | **PARTIEL / CONTRADICTOIRE** | Le plein écran est demandé via `fullScreenIntent` ([system_reminder_service.dart#L115](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L115)), mais la boucle audio `MediaPlayer` dépend de l'écran Flutter ([alarm_ringing_screen.dart#L75](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L75)). Sans ouverture Flutter, le son ne boucle pas. |
| **D3** : Téléphone utilisé (autre app) : bannière persistante Arrêter / Reporter, son en boucle | **PARTIEL** | Présente les actions Arrêter / Reporter dans la notification flottante ([system_reminder_service.dart#L124-L136](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L124-L136)), mais le son ne boucle pas et elle s'éteint après 60s (`timeoutAfter: 60000`, [L119](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L119)). |
| **D4** : App ouverte : alarme plein écran dans l'app ; notification → bandeau seul sans push OS | **PARTIEL** | Catégorie notification conforme (push annulé par `plugin.cancel`, [system_reminder_service.dart#L396](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L396)). Mais catégorie alarme en doublon : `plugin.show` est émis en plus de l'écran plein écran ([L401](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L401)). |
| **D5** : Sonnerie limitée à 5 minutes, puis entrée « Rappel manqué » visible dans la page | **CONTRADICTOIRE / ABSENT** | La minuterie est réglée sur 60 secondes ([system_reminder_service.dart#L119](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L119) et [alarm_ringing_screen.dart#L17](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L17)), et l'entrée « Rappel manqué » est **totalement absente** du code. |
| **D6** : Reporter = 10 minutes fixes, nombre illimité | **CONFORME** | Replanification à +10 minutes fixes sans restriction ([system_reminder_service.dart#L45](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L45) et [alarm_ringing_screen.dart#L128](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L128)). |
| **D7** : Écran alarme minimal (type, heure, éléments), aucun nom ni montant ; PIN pour « Voir » | **PARTIEL / CONTRADICTOIRE** | Aucun montant affiché (conforme). Mais le nom du client et le titre de la commande sont affichés ([alarm_ringing_screen.dart#L203](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/alarm_ringing_screen.dart#L203)), et le bouton « Voir » menant au PIN est **absent**. |
| **D8** : Modes par catégorie (alarme/notif/désactivé) ; apprenti en alarme par défaut | **PARTIEL** | Les 3 modes existent ([settings_repository.dart#L15](file:///home/othnelio/Angela/Angela_Deesse/lib/data/repositories/settings_repository.dart#L15)), mais l'échéance d'apprenti est en `notification` par défaut ([alert_engine.dart#L455](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/alert_engine.dart#L455) via `kDefaultModePayments`), pas en alarme. |
| **D9** : Page notifications = alertes courantes + historique 30j (arrêtée, reportée, manquée) | **PARTIEL / ABSENT** | Alertes courantes présentes ([notifications_screen.dart#L91](file:///home/othnelio/Angela/Angela_Deesse/lib/screens/notifications_screen.dart#L91)), mais **l'historique de 30 jours est totalement absent**. |
| **D10** : Une seule source de vérité (AlertEngine) ; aucun doublon de signal | **PARTIEL** | Source unique respectée (`AlertEngine`), mais doublon effectif au premier plan pour les alarmes (notification système + plein écran Flutter simultanés, [system_reminder_service.dart#L401](file:///home/othnelio/Angela/Angela_Deesse/lib/data/services/system_reminder_service.dart#L401)). |

