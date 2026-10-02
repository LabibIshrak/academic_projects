# BongoJatra Flutter App

Flutter frontend for BongoJatra, a Bangladesh unified transport prototype inspired by Omio.

## Requirements

- Flutter 3.10+
- Backend running on port `8080`
- Firebase project from [console.firebase.google.com](https://console.firebase.google.com)
- Optional Groq API key from [console.groq.com](https://console.groq.com)

## Firebase Setup

1. Create a Firebase project.
2. Add an Android app with this package name:
   `com.example.bongojatra_flutter`
3. Download `google-services.json`.
4. Place it in:
   `bongojatra-flutter/android/app/google-services.json`
5. Enable Google sign-in in Firebase Authentication.

The app also supports a demo sign-in path so the prototype stays usable while Firebase is being configured.

## Backend

```bash
cd bongojatra-backend/src
javac -d ../out *.java
GROQ_API_KEY=your_key java -cp ../out Server
```

## Flutter

```bash
cd bongojatra-flutter
flutter pub get
flutter run
```

## Backend URL

Edit `lib/services/api_service.dart` if needed:

| Device | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:8080/api` |
| iOS simulator | `http://localhost:8080/api` |
| Web browser | `http://localhost:8080/api` |
| Physical device | `http://YOUR_PC_IP:8080/api` |

## Notes

- No real payments are made.
- No map API or photos are used.
- Ticket PDFs are generated with the `pdf` and `printing` packages.
- QR codes encode the booking reference.
