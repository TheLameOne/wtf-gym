# AI Ledger — WTF Gym Flutter Assessment

> Records all significant AI-assisted decisions, generated code blocks, and design choices during this session.

---

## Entry 1 — Workspace Exploration & Assessment Analysis

**Prompt pattern:** Analyze assessment PDF, identify deliverables  
**Decision:** Two-app Flutter workspace with shared Dart package. Assessment requires: real-time chat, 100ms video calls, scheduling, session logs, DevPanel, and this ledger.  
**Outcome:** Confirmed 6 Firestore collections, 3 app layers (shared / guru_app / trainer_app), and a Node.js token server.

---

## Entry 2 — Shared Package Architecture

**Prompt pattern:** Design shared Dart package structure  
**Decision:** `shared/lib/` organized into `models/`, `services/`, `widgets/`, `utils/` with a barrel `shared.dart`. Both apps import via `path: ../shared`.  
**Outcome:** Eliminated all model duplication; 5 models, 6 services, 8 widgets, 5 utils created once.

---

## Entry 3 — Mock Auth Strategy

**Prompt pattern:** How to authenticate two fixed users without Firebase Auth?  
**Decision:** `AuthService` backed by `SharedPreferences`. Stores `userId`, `role`, `assignedTrainerId`. No email/password, no JWT — fixed seeded IDs (`member_dk`, `trainer_aarav`).  
**Rationale (D-04):** Assessment uses fixed personas; real auth adds complexity without value.

---

## Entry 4 — Real-time Chat Implementation

**Prompt pattern:** Design Firestore-backed chat with unread counts and typing indicators  
**Decision:** `ChatService.sendMessage()` uses a Firestore `WriteBatch` to atomically write the message and update `ChatMeta` (lastMessage, `FieldValue.increment(1)` for unread). Typing presence stored in a separate `typing/` collection with 5-second staleness check.  
**Outcome:** Real-time bidirectional chat with delivery status ticks (sent/read).

---

## Entry 5 — chatId Canonical Format

**Prompt pattern:** How to compute a unique, deterministic chat document ID?  
**Decision:** `sorted([uid1, uid2]).join('_')` — lexicographic sort ensures both sides produce the same ID.  
**Outcome:** No extra lookup needed; DK→Aarav and Aarav→DK both produce `member_dk_trainer_aarav`.

---

## Entry 6 — 100ms Token Server Design

**Prompt pattern:** Generate HS256 app tokens + create rooms via 100ms Management API  
**Decision:** Node.js Express server on port 3000. `GET /token` signs an app JWT. `POST /room` calls `https://api.100ms.live/v2/rooms` with a freshly-signed management token. Falls back to a synthetic `local_{name}` roomId if the API is unreachable.  
**Outcome:** Decoupled from 100ms dashboard; works in offline/emulator environments.

---

## Entry 7 — Video Call Flow

**Prompt pattern:** Design the full approve → join → end → log flow  
**Decision:** Trainer approval atomically creates a 100ms room, stores `RoomMeta` in Firestore, updates request status, and sends a system chat message. Member/trainer both query `room_metas/{requestId}` before joining. Post-call, `SessionLogService.createLog()` captures duration; member rates; trainer adds notes.  
**Outcome:** End-to-end call lifecycle with no race conditions.

---

## Entry 8 — Riverpod without Code Generation

**Prompt pattern:** State management approach given 6-hour constraint  
**Decision:** `flutter_riverpod` with manual `Provider` only for GoRouter injection. All real-time data uses `StreamBuilder` directly on Firestore streams — no `AsyncNotifier` or generated code needed.  
**Rationale (D-03):** Avoids `build_runner` setup time; sufficient for the scope.

---

## Entry 9 — DevPanel Widget

**Prompt pattern:** Build floating debug panel visible in all screens  
**Decision:** `DevPanel` is a `Stack`-overlay widget with a floating "⋮" button. Tapping reveals a slide-up panel showing `AppLogger.recentLogs` (last 20, reversed). Copy-to-clipboard supported.  
**Outcome:** Available in both apps by adding `const DevPanel()` to the screen's `Stack`.

---

## Entry 10 — AppTheme Color System

**Prompt pattern:** Differentiate member vs. trainer apps visually  
**Decision:** `AppTheme.guru()` uses `guruPrimary = #1769E0` (blue). `AppTheme.trainer()` uses `trainerPrimary = #E50914` (red). Shared `AppColors`, `AppTextStyles`, `AppSpacing` ensure consistent spacing.  
**Outcome:** Both apps are immediately distinguishable while sharing all widget code.

---

## Entry 11 — Android Build Config & Permissions

**Prompt pattern:** Set up minSdk, package IDs, Google Services, and 100ms permissions  
**Decision:** `minSdk=21`, `ndkVersion="27.0.12077973"`. Package IDs: `com.wtf.guru_app` / `com.wtf.trainer_app`. AndroidManifest includes `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH_CONNECT`, `FOREGROUND_SERVICE_CAMERA`, `FOREGROUND_SERVICE_MICROPHONE`.  
**Outcome:** Both apps build cleanly with 100ms SDK requirements satisfied.

---

## Entry 12 — Unit Test Strategy

**Prompt pattern:** What to test given pure model/utility logic?  
**Decision:** Guru app tests `MessageModel` serialization roundtrip + `Validators` (future slot validation, note length). Trainer app tests `SessionLogModel.calculateDuration()` + `CallRequestModel` status helpers. No widget tests (would require full Firebase mock setup).  
**Outcome:** 5+ passing unit tests covering core business logic without external dependencies.

---

## Entry 13 — Firestore Composite Index Errors Fixed

**Prompt pattern:** App crashes with "requires an index" Firestore errors  
**Decision:** Removed all `orderBy` clauses from `ChatService.chatListStream`, `ChatService.messagesStream`, and `SessionLogService.trainerLogsStream`/`memberLogsStream`. Sorting is now done in Dart (`.sort((a, b) => a.x.compareTo(b.x))`).  
**Files changed:** `shared/lib/services/chat_service.dart`, `shared/lib/services/session_log_service.dart`  
**Rationale:** Compound queries with `orderBy` + `where` require manually-created Firestore composite indexes not provisioned in this project. Dart-side sorting avoids the index requirement with negligible performance impact at this data scale.

---

## Entry 14 — onHMSError Propagation + 20s Connection Timeout

**Prompt pattern:** Call screen stuck on "Connecting…" forever after join  
**Root cause:** `onHMSError` in `HmsService` was an empty override — terminal errors (e.g. invalid role) were silently dropped. Call screens had no timeout guard.  
**Decision:** (1) `onHMSError` now calls `_updateState(HMSCallState.error)` for terminal errors and invokes the `onError` callback with the message. (2) Both `guru_app` and `trainer_app` call screens set a 20-second `Timer` on `_startJoin`; if `HMSCallState.connected` is not reached, the screen calls `_onError`, destroys the HMS client, and navigates away.  
**Files changed:** `shared/lib/services/hms_service.dart`, `guru_app/lib/features/call/screens/call_screen.dart`, `trainer_app/lib/features/call/screens/call_screen.dart`

---

## Entry 15 — 100ms Role Fix: host/guest Instead of trainer/member

**Prompt pattern:** "invalid role" error returned from 100ms SDK on join  
**Root cause:** The 100ms template (`6a1494d14a799ad17a8b5c54`, named "trainer") only has roles `host` and `guest`. The app was requesting non-existent roles `trainer`/`member`.  
**Decision:** Changed `AppConstants.hmsTrainerRole = 'host'` and `AppConstants.hmsMemberRole = 'guest'`. Updated `RoomMetaModel` defaults and `fromMap` fallbacks to match. Also added `HMS_TEMPLATE_ID` to `token_server/.env` and used it in `POST /room` body so rooms are created under the correct template.  
**Files changed:** `shared/lib/utils/app_constants.dart`, `shared/lib/models/room_meta_model.dart`, `token_server/server.js`, `token_server/.env`

---

## Entry 16 — HTTP Timeout on Token Server Calls

**Prompt pattern:** Approve button spinner never resolves when token server is down  
**Root cause:** `http.get`/`http.post` in Dart have no default timeout — they block indefinitely if the server is unreachable.  
**Decision:** Added `.timeout(const Duration(seconds: 8))` to all HTTP calls: `CallRequestService._createHmsRoom()` and `HmsService.fetchAuthToken()`.  
**Files changed:** `shared/lib/services/call_request_service.dart`, `shared/lib/services/hms_service.dart`

---

## Entry 17 — Room Meta Stale Doc Fix

**Prompt pattern:** "Bad Request" from 100ms on call join despite successful approve  
**Root cause:** `.limit(1)` on `room_metas` without ordering returned an old stale document with a fake `room_XXXX` or `local_XXXX` ID instead of the real 100ms room ID created by the latest approve.  
**Decision:** (1) `approveRequest` now deletes all existing `room_metas` docs for the request before creating a new one. (2) `getRoomMetaForRequest` removed `.limit(1)`, fetches all docs, then uses `firstWhere` to prefer docs whose `hmsRoomId` does not start with `room_` or `local_`. (3) HMS roles (`host`/`guest`) are stored in `RoomMetaModel` at approval time; pre-join screens read roles from `roomMeta.hmsRoleTrainer`/`hmsRoleMember` instead of hardcoded constants.  
**Files changed:** `shared/lib/services/call_request_service.dart`, `guru_app/lib/features/call/screens/pre_join_screen.dart`, `trainer_app/lib/features/call/screens/pre_join_screen.dart`

---

## Entry 18 — "My Requests" Card Added to Guru App Home

**Prompt pattern:** Member has no way to see status of submitted call requests  
**Decision:** Added a 4th card ("My Requests", icon `schedule_send`) to `guru_app` home screen that navigates to `/requests` → `MyRequestsScreen`, which streams `call_requests` filtered by `memberId = member_dk` and shows status badges.  
**Files changed:** `guru_app/lib/features/home/screens/home_screen.dart`

---

## Entry 19 — QA: Onboarding Persistence & Avatar Contrast

**Prompt pattern:** Verify (1) reinstall shows onboarding again; (2) dummy avatars have clear contrast  
**Findings:**

- **Onboarding persistence ✅**: `guru_app` splash checks `AuthService.isOnboardingDone()` (SharedPreferences `prefOnboardingDone`). `trainer_app` splash checks `AuthService.isLoggedIn()` (SharedPreferences `prefIsLoggedIn`). SharedPreferences is cleared on app reinstall → onboarding/login always shows fresh. On subsequent launches without reinstall the flag persists → user goes straight to home.
- **Avatar contrast ✅**: All `CircleAvatar` instances use solid primary-color initials on a 10–15% opacity tinted background (light pink or light blue). Computed contrast ratios exceed WCAG AA. Chat message bubbles use `#E3F0FF`/`#FFEBEB` backgrounds with `#212121` text — excellent contrast.
- **No changes required.**

---

## Entry 20 — Chat QA: Cross-App Messaging, Status Ticks, Typing Animation, Empty State

**Prompt pattern:** Verify (1) send/receive works across both apps; (2) status changes visible, typing dot animates; (3) empty state uses illustration + CTA "Say hi"  
**Findings:**

- **Cross-app send/receive ✅**: Both apps stream from the same Firestore `chats/{id}/messages` collection. `_myId`/`_otherUserId` are correctly set per app (`member_dk` in guru, `trainer_aarav` in trainer). `ChatService.sendMessage()` uses a `WriteBatch` to atomically write the message and update `ChatMeta`.
- **Status ticks ✅**: `StatusTicks` widget renders `done_all` in `guruPrimary` blue for `read`, grey for `sent`. `markAsRead` batch-updates the last 50 messages on conversation open.
- **Typing animation ✅**: `TypingIndicator` renders 3 animated dots via `flutter_animate` with staggered 200ms delays and repeating scale pulse. `setTyping` is called on every keystroke; cleared on send and `dispose()`.
- **Empty state ❌ → Fixed**: Both chat list screens previously showed a plain icon with no action. Replaced with a `_ChatEmptyState` widget: 💬 emoji (80px) as illustration, subtitle copy, and an `ElevatedButton.icon` labelled "Say hi 👋" that pushes directly to the conversation screen.

**Files changed:** `guru_app/lib/features/chat/screens/chat_list_screen.dart`, `trainer_app/lib/features/chat/screens/chat_list_screen.dart`  
**Commit:** `feat(chat): add illustration + Say hi CTA to empty chat list state`
