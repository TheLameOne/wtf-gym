# WTF Gym — 100ms Token Server

A lightweight Node.js/Express server that:
- Issues 100ms **app tokens** (JWTs) for Flutter clients to join rooms
- Creates 100ms **rooms** via the Management API on trainer approval

## Prerequisites

- Node.js 18+
- A [100ms](https://dashboard.100ms.live) account with an app configured

## Setup

1. Install dependencies:
   ```bash
   cd token_server
   npm install
   ```

2. Copy the example env file and fill in your credentials:
   ```bash
   cp .env.example .env
   ```

   Edit `.env`:
   ```
   HMS_APP_ACCESS_KEY=your_app_access_key
   HMS_APP_SECRET=your_app_secret
   HMS_TEMPLATE_ID=your_template_id   # optional but recommended
   ```

   Find these in the 100ms Dashboard → **Developer** → **App credentials**.

3. Start the server:
   ```bash
   node server.js
   ```
   The server listens on `http://localhost:3000` by default.

---

## Endpoints

### `GET /health`
Returns `{ status: 'ok' }`. Use to verify the server is running.

---

### `GET /token?userId=<id>&role=<role>&roomId=<id>`

Generates a signed app JWT for the given user to join a specific room.

| Query param | Required | Description |
|-------------|----------|-------------|
| `userId`    | ✅ | Any stable user identifier (e.g. `member_dk`, `trainer_aarav`) |
| `role`      | ✅ | One of: `host`, `guest`, `trainer`, `member` |
| `roomId`    | ✅ | The 100ms room ID (obtained from `POST /room`) |

**Response:**
```json
{ "token": "<signed-jwt>" }
```

Tokens are valid for **24 hours** (HS256, signed with `HMS_APP_SECRET`).

---

### `POST /room`

Creates a new 100ms room via the Management API.

**Request body:**
```json
{ "name": "some-unique-room-name" }
```

**Response (success):**
```json
{ "id": "63f...", "name": "some-unique-room-name" }
```

**Response (fallback — API unreachable):**
```json
{ "id": "local_some-unique-room-name", "name": "...", "fallback": true }
```
The fallback `local_*` roomId allows the app to continue in dev without 100ms API access.

---

## How it fits into the app

```
Trainer approves call request
  → Flutter: POST /room   → { id: hmsRoomId }
  → Firestore: room_metas/{requestId} = { hmsRoomId, hmsRoleTrainer: "host", hmsRoleMember: "guest" }

Member/Trainer open PreJoin screen
  → Flutter: GET /token?userId=&role=&roomId=   → { token }
  → HMSSDK.join(authToken: token, userName: name)

Trainer ends call
  → HMSSDK.endRoom()   → all participants removed

Network loss
  → onReconnecting callback → spinner shown
  → onReconnected callback  → call resumes
```

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HMS_APP_ACCESS_KEY` | ✅ | 100ms app access key |
| `HMS_APP_SECRET` | ✅ | 100ms app secret (used to sign JWTs) |
| `HMS_TEMPLATE_ID` | Optional | 100ms template ID; if omitted, rooms use the account default |
| `PORT` | Optional | Server port (default: 3000) |
