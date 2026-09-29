# Local Android testing before deployment

This setup runs the Flutter mobile app in an Android emulator and the Node.js
backend on your Windows computer. Firebase and online maps still need internet.
Nothing is deployed publicly.

## Current verification status

- Local backend health and Firebase connection passed.
- Existing route names, no-match search, and unauthenticated GPS rejection passed.
- Two backend unit tests and two Flutter tests passed.
- Flutter analysis has no errors, with four existing warnings and one style notice.
- `TransitLocal` booted successfully and its location was set near Galle.
- A fresh APK has NOT been built or installed. The first build stalled downloading
  NDK 28.2.13676358 and was stopped. Emulator-to-backend connectivity and the
  complete driver/passenger flow remain unverified.

Complete the missing NDK installation before rebuilding. In Android Studio's
SDK Manager, select the existing SDK at `D:\apps\androidsdk`, open SDK Tools,
enable Show Package Details and install NDK (Side by side) 28.2.13676358.
Alternatively, run the already installed SDK manager:

```powershell
& 'D:\apps\androidsdk\cmdline-tools\latest\bin\sdkmanager.bat' --sdk_root=D:\apps\androidsdk 'ndk;28.2.13676358'
```

This downloads a large Android build dependency; it is not a paid service.
If the download stalls again, check access to Google's Android download servers.
The cancelled build log is in `$env:TEMP\transit-android-build.log`.

## Start the backend

From the repository root, in a terminal:

```powershell
cd backend
npm start
```

Keep this terminal running. The existing `.env` and `firebase-key.json` are
required. Never put the service-account key in the mobile app or commit it.

In another terminal:

```powershell
Invoke-RestMethod http://localhost:5000/api/health
Invoke-RestMethod http://localhost:5000/api/routes
```

Health must report `firebaseConnected: true`. The server's startup banner alone
does not prove the database connection works.

## Start the mobile app

Flutter is configured to use the existing SDK at `D:\apps\androidsdk`.
Restart the IDE if it still displays Flutter initialization indefinitely.
The `TransitLocal` Android 36 virtual device has been created using the installed
system image. Start it with `flutter emulators --launch TransitLocal`, or select
it in Android Studio's Device Manager. Then run from the repository root:

```powershell
cd public_transport_tracker
flutter devices
flutter run -d emulator-5554 --dart-define=BACKEND_URL=http://10.0.2.2:5000
```

Replace `emulator-5554` with the device ID shown by `flutter devices`.
The root workspace also has a VS Code launch configuration for this setup.
Select an Android emulator before starting it.

`10.0.2.2` is the Android emulator's address for your computer. `localhost`
inside the emulator refers to the emulator itself. HTTP access is enabled
only in the Android debug manifest. An eventual release should use HTTPS.

For a physical phone on the same network, pass your computer's LAN IP instead.
For a web test, pass `http://localhost:5000`. Do not add `/api` to BACKEND_URL.

## Checks to perform in order

- [ ] Open the app; welcome and login screens appear without exceptions.
- [ ] Create a passenger using email/password; sign out and sign in again.
- [ ] Create a driver through the main signup screen's driver option.
      The separate employee/staff login is still a simulation; do not use it.
- [ ] Driver can load routes, select route 502, and start a trip.
- [ ] Grant location permission and set the emulator location near Galle.
- [ ] On a second emulator/device, sign in as a passenger and open Track.
- [ ] Select pickup and destination near actual stops, then search.
- [ ] Select the matching bus and observe GPS movement while changing the
      driver's emulator location. Keep the driver screen open.
- [ ] End the driver trip; a fresh search should no longer return that trip.
- [ ] Stop/restart the server and note whether the app recovers or shows an error.

Two routes were present during the initial database check: 502 and 344.
For route 502, use these coordinates (latitude, longitude):

| Stop | Latitude | Longitude |
| --- | --- | --- |
| Galle Bus Stand | 6.0329 | 80.2168 |
| Karapitiya Junction | 6.0527 | 80.2215 |
| University Entrance | 6.0592 | 80.2238 |
| Hapugala Junction | 6.0645 | 80.2261 |

Pick the first stop for pickup and a later stop for destination. Search matches
stops within 500 metres and requires an active driver trip. An emulator's default
location may be in another country. In its extended controls, use Location to
set a point near the route. With adb, longitude comes first:

```powershell
& 'D:\apps\androidsdk\platform-tools\adb.exe' -s emulator-5554 emu geo fix 80.2168 6.0329
```

## Automated checks

From `backend`: `npm test` (route matching and existing route-schema compatibility).
From `public_transport_tracker`: `flutter test` (configuration and welcome/login).
From `public_transport_tracker`: `flutter analyze` (static diagnostics).

These checks do not establish that the full two-device workflow works.

## Development still required before public deployment

- Correct ETA speed units and calculate arrival at the selected pickup stop.
- Replace hardcoded driver occupancy/capacity, send actual crowd-report location,
  and persist numeric occupancy consistently.
- Restrict signup roles, verify trip ownership on GPS writes, and authenticate
  Socket.IO send events.
- Validate stored sessions and implement expiry/logout handling properly.
- Show stale/offline locations and trip-ended states; test reconnection.
- Complete or hide simulated staff login, admin data and emergency actions.
- Configure Android-specific Firebase/push notifications if included in scope.
- Check map attribution/caching and background GPS behaviour on a physical phone.
- Keep booking/payment outside the minimum tracking demo unless required.

Local startup fixes do not make the project production ready.
