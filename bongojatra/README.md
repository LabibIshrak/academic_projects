# BongoJatra 🚌🚂⛴

**Bangladesh Unified Transport System** — Bus · Train · Launch, one search.

A university prototype (1.5 credits) that helps passengers find the best transport option between Bangladeshi cities using AI-powered recommendations.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Plain Java 17 (com.sun.net.httpserver) |
| Frontend | Flutter 3.10+ |
| AI | Groq API (llama-3.1-8b-instant) |

## Quick Start

### 1. Get a Groq API Key
Visit [console.groq.com](https://console.groq.com) and create a free API key.

### 2. Start Backend

```bash
cd bongojatra-backend/src
javac -d ../out *.java

# Windows PowerShell
$env:GROQ_API_KEY="your_key_here"
java -cp ../out Server

# Linux / macOS
GROQ_API_KEY=your_key java -cp ../out Server
```

### 3. Start Flutter App

```bash
cd bongojatra-flutter
flutter pub get
flutter run
```

> **Important:** Adjust `baseUrl` in `lib/services/api_service.dart` for your device type.

## Routes Available

| Route | Transport Types |
|-------|----------------|
| Dhaka ↔ Chattogram | Bus (AC, Non-AC), Train |
| Dhaka ↔ Sylhet | Bus (AC, Non-AC), Train |
| Dhaka ↔ Rajshahi | Bus (AC, Non-AC), Train |
| Dhaka ↔ Khulna | Bus (AC, Non-AC), Train, **Launch** |

## Project Structure

```
bongojatra-backend/
  src/
    Server.java           ← HttpServer on port 8080
    TransportData.java    ← Mock transport data
    AIService.java        ← Groq API integration
    CorsUtil.java         ← CORS headers

bongojatra-flutter/
  lib/
    main.dart
    theme/app_theme.dart
    models/
      transport_option.dart
      route_response.dart
    services/api_service.dart
    screens/
      home_screen.dart
      results_screen.dart
      detail_screen.dart
```

## Disclaimer

This is a university prototype. No real bookings are made.
All prices are in BDT (৳).
