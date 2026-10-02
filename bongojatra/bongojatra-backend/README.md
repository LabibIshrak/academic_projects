# BongoJatra Backend

Plain Java 17 backend for the BongoJatra university prototype. No Spring Boot, no Maven, no database.

## Requirements

- Java 17+
- Optional Groq API key from [console.groq.com](https://console.groq.com)

## Run

```bash
cd bongojatra-backend/src
javac -d ../out *.java
GROQ_API_KEY=your_key java -cp ../out Server
```

Windows PowerShell:

```powershell
cd bongojatra-backend/src
javac -d ../out *.java
$env:GROQ_API_KEY="your_key"
java -cp ../out Server
```

Expected startup message:

```text
BongoJatra running on :8080
```

If `GROQ_API_KEY` is missing, route suggestions use the local fallback logic silently.

## Endpoints

- `POST /api/auth/google`
- `GET /api/cities`
- `POST /api/route/suggest`
- `GET /api/seats/{optionId}`
- `POST /api/booking/confirm`
- `GET /api/booking/history`
- `POST /api/booking/cancel`

Authenticated endpoints expect:

```text
Authorization: Bearer base64email
```
