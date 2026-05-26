# WTF Gym — Flutter AI-Native Assessment

## Two-app Flutter workspace: `guru_app` (member) + `trainer_app` (trainer)

---

## Architecture

```
wtf-gym/
├── shared/          # Dart package: models, services, widgets, utils
├── guru_app/        # Flutter app for member "DK"
├── trainer_app/     # Flutter app for trainer "Aarav"
└── token_server/    # Node.js 100ms auth token server
```

See [ARCHITECTURE.md](ARCHITECTURE.md) and [DECISIONS.md](DECISIONS.md) for full details.

---

## Prerequisites

| Tool             | Version  |
| ---------------- | -------- |
| Flutter          | ≥ 3.10.0 |
| Dart             | ≥ 3.0.0  |
| Node.js          | ≥ 18     |
| Android emulator | API 21+  |

---

## 1 · Token Server

```bash
cd token_server
cp .env.example .env          # fill in HMS_APP_ACCESS_KEY + HMS_APP_SECRET
npm install
npm start                     # runs on http://localhost:3000
```

The Android emulator reaches it at `http://10.0.2.2:3000`.

---

## 2 · Guru App (member "DK")

```bash
cd guru_app
flutter pub get
flutter run                   # launches on connected Android emulator
```

### Screens

- **Onboarding** — 2-slide PageView → Create Profile
- **Create Profile** — name pre-filled "DK", trainer picker from Firestore
- **Home** — 3 feature cards (Chat / Schedule / Sessions)
- **Chat** — real-time Firestore messaging, typing indicator, quick replies
- **Schedule** — TableCalendar (next 3 days) + 30-min time slots + note
- **My Requests** — live status updates (pending → approved → join call)
- **Sessions** — filtered session log list with star ratings
- **Pre-Join** — mic/cam toggles + permission request
- **Call** — 100ms video grid with PiP, mute/video/flip/end controls
- **Post-Call Rating** — 1-5 stars

---

## 3 · Trainer App (trainer "Aarav")

```bash
cd trainer_app
flutter pub get
flutter run                   # on second emulator / device
```

### Screens

- **Login** — one-tap mock login as Aarav
- **Home** — 4-tile grid (Members / Messages / Requests / Sessions)
- **Members** — list of assigned members with chat shortcut
- **Chat** — same real-time chat (opposite side)
- **Requests** — approve (creates 100ms room) / decline with reason modal
- **Sessions** — trainer notes editable inline, member rating shown
- **Pre-Join / Call / Post-Call Notes** — mirror of member flow

---

## 4 · Tests

```bash
cd guru_app  && flutter test
cd trainer_app && flutter test
```

---

## Firebase

Both apps share project `wtf-gym-2b12f`.  
Firestore rules should allow authenticated read/write for development.

---

## AI Ledger

See [AI_LEDGER.md](AI_LEDGER.md) for the full record of AI-assisted decisions.
