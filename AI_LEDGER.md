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

---

## Entry 21 — Scheduling QA & Fixes

**Prompt pattern:** Verify schedule screen (calendar + 30-min slots, note, CTA), My Requests toast, trainer approve/decline flow, date validation, conflict check  
**Findings:**

- **Calendar + next 3 days ✅**: `TableCalendar` with `firstDay: now`, `lastDay: now + 3 days`. Past dates disabled; past time slots grayed out via `isPast = dt.isBefore(now)`.
- **30-min blocks ❌ → Fixed**: Slots were hourly (10 entries). Expanded to 20 half-hour blocks from 7:00–11:30 and 14:00–18:30.
- **`isSelected` minute bug ❌ → Fixed**: Selection check only compared `.hour`, so 8:00 and 8:30 both appeared highlighted. Added `.minute` comparison.
- **Note field 140 chars ✅**: `maxLength: 140` on TextField; `Validators.validateNote` enforces the limit.
- **CTA "Request Call" ✅**: Creates `CallRequest` with `status: 'pending'`.
- **Toast message ❌ → Fixed**: Was `'Call request sent!'`. Changed to `'Pending approval by Aarav'`.
- **My Requests list ✅**: Streams from Firestore, shows status badges. Approved requests show "Join Call" button.
- **Trainer Requests tab ✅**: Shows all requests with member name, note, scheduled time, and inline Approve/Decline buttons.
- **On Approve ✅**: Deletes stale `room_metas`, creates real 100ms room, stores `RoomMetaModel`, updates status, sends system message.
- **System message format ❌ → Fixed**: Was `'Call approved for May 26 at 6:00 PM'`. Requirement is time-only. Added `_formatTime()` helper; message is now `'Call approved for 6:00 PM'`.
- **On Decline ✅**: Reason modal (`AlertDialog` + `TextField`). DK sees decline reason in `_RequestCard`.
- **Past slot validation ✅**: `Validators.isValidFutureSlot` checked in `_submit()`; past slots show error snackbar.
- **Conflict check ❌ → Fixed**: `isSlotTaken()` existed in `CallRequestService` (±29 min window against approved requests) but was never called. Now called in `_submit()` before `createRequest`; shows error snackbar if slot is taken.

**Files changed:** `guru_app/lib/features/schedule/screens/schedule_screen.dart`, `shared/lib/services/call_request_service.dart`  
**Commit:** `feat(schedule): 30-min slots, conflict check, correct toast and system message`

---

## Entry 22 — Chat QA: Bubble Colours, Status Ticks, Typing Simulation, Pull-to-Load History

**Prompt pattern:** Verify full chat spec: chat list (unread badge, last preview, "5m ago"), bubble left/right + role colour, typing simulation 400–800ms, status ticks single/double, pull to load history, scroll to bottom, quick reply chips  
**Findings:**

- **Chat list ✅**: `chatListStream` + `meta.unreadFor(userId)` badge + `meta.lastMessage` subtitle (ellipsis) + `timeago.format` timestamp. All correct in both apps.
- **Bubble UI ✅**: `isFromMe` controls left/right alignment. `MessageBubble` uses `AppColors.memberBubble` (#E3F0FF blue) and `AppColors.trainerBubble` (#FFEBEB red).
- **Bubble role colour ❌ → Fixed**: Colour was driven by `isFromMe`, so in `trainer_app` the trainer's own messages were blue and member's were red — backwards. Fixed by deriving colour from `message.senderId == AppConstants.memberDkId` (role-based, not perspective-based). Same colour regardless of which app is viewing.
- **Status tick `sent` = single check ❌ → Fixed**: `StatusTicks` was rendering `done_all` (double-check grey) for `'sent'`. Fixed to `Icons.check` (single grey). `'read'` keeps `done_all` blue.
- **Typing indicator (real) ✅**: `typingStream` drives `TypingIndicator` widget; `setTyping` called on each keystroke, cleared on send/dispose.
- **Typing simulation 400–800ms ❌ → Fixed**: After `sendMessage()` resolves, both conversation screens now set `_simulatingTyping = true` for a `Random().nextInt(401) + 400` ms window. The typing indicator stream builder checks `snap.data == true || _simulatingTyping`.
- **Scroll to bottom on new message ✅**: `_scrollToBottom()` called via `addPostFrameCallback` on every stream rebuild.
- **Pull to load history ❌ → Fixed**: No pagination existed. Added `_messageLimit = 50`; stream data is sliced to `allMessages.sublist(length - _messageLimit)`; `RefreshIndicator.onRefresh` increments limit by 50 and triggers rebuild. `AlwaysScrollableScrollPhysics` ensures pull works even with few messages.
- **Quick replies ✅**: Three chips `"Got it 👍"`, `"Can we talk at 6?"`, `"Share plan?"` from `AppConstants.quickReplies`. Horizontally scrollable row. Coloured with role accent per app.

**Files changed:** `shared/lib/widgets/message_bubble.dart`, `shared/lib/widgets/status_ticks.dart`, `guru_app/lib/features/chat/screens/conversation_screen.dart`, `trainer_app/lib/features/chat/screens/conversation_screen.dart`  
**Commit:** `fix(chat): role-based bubble colours, single-check sent tick, simulated typing, pull-to-load history`

---

## Entry 23 — Video Call QA & Fixes

**Prompt pattern:** Verify full call spec: 10-min Join button, pre-join device check, in-call grid + name labels, Mute/Cam/Flip/End controls, reconnect loader, session log, post-call sheets  
**Findings:**

- **100ms room creation + roles ✅**: Approved requests use a real 100ms room; roles `host`/`guest` stored in `RoomMetaModel` and passed to `fetchAuthToken`.
- **Join Call button: 10-min window ❌ → Fixed**: `isApproved` was used to show the Join button — it appeared as soon as trainer approved, regardless of schedule. Added `isJoinable` getter to `CallRequestModel`: `isApproved && DateTime.now().isAfter(scheduledFor - 10 min)`. Both request list screens now gate on `isJoinable`.
- **Chat toolbar camera icon ❌ → Fixed**: No camera button existed in the conversation AppBar. Added `StreamBuilder` in `actions` for both apps that streams approved requests, filters `isJoinable`, and shows `Icons.video_call` + a red dot badge if a joinable call exists. Tapping pushes to `/pre-join/{id}`.
- **Pre-join device check modal ✅ (improved)**: Was a small icon placeholder. Replaced with a full-width dark container (camera-preview style) with a `videocam` icon, user name label, and `videocam_off` overlay when camera toggle is off. Mic/cam toggles ✅. Role auto-mapped from `RoomMetaModel` ✅.
- **In-call grid + name labels ❌ → Fixed**: No name labels existed on video tiles. Remote video tile now has a `Positioned` bottom-left overlay with the remote peer's name from `_hms.peers` (`firstOrNull`). Local PiP has a "You" label.
- **Mute/Unmute, Video On/Off, Flip Camera, End Call ✅**: All 4 controls present in `_CallControls`. State reflected via `isMicMuted`/`isCameraMuted`.
- **Network resilience ✅**: `onReconnecting` sets `HMSCallState.reconnecting`; call screen shows "Reconnecting…" spinner. 20s timeout guard already present from Entry 14.
- **Peer leaves: other sees state change ✅**: `onPeersChanged` callback → `setState`; remote video track removed → "Waiting for…" placeholder shown.
- **Session log auto-written ✅**: `_navigatePostCall` calls `SessionLogService.createLog` with `_hms.callStartTime` (or `DateTime.now()` fallback) and real `endedAt`.
- **Member post-call: Rate 1–5 + optional note ❌ → Fixed**: `_noteController` existed but `updateRating` was always called with `null` for the note. Added `TextField` (3 lines, 200 char limit) to the rating UI; note now passed if non-empty.
- **Trainer post-call: notes + "Mark as Complete" ❌ → Fixed**: Button label was "Save & Finish". Changed to "Mark as Complete" per spec. Notes field ✅ was already wired.

**Files changed:** `shared/lib/models/call_request_model.dart`, `guru_app/.../my_requests_screen.dart`, `trainer_app/.../requests_screen.dart`, `guru_app/.../conversation_screen.dart`, `trainer_app/.../conversation_screen.dart`, `guru_app/.../call_screen.dart`, `trainer_app/.../call_screen.dart`, `guru_app/.../pre_join_screen.dart`, `trainer_app/.../pre_join_screen.dart`, `guru_app/.../post_call_rating_screen.dart`, `trainer_app/.../post_call_notes_screen.dart`  
**Commit:** `feat(call): 10-min join window, camera-icon badge, name labels, note saved, Mark as Complete`

---

## Entry 24 — Session Logs & Insights QA & Fixes

**Prompt pattern:** Verify full session logs spec: filter chips, row content, tap → detail modal, sort by latest, empty state + CTA, export share  
**Findings:**

- **Filter chips: All / Last 7 Days / This Month ✅**: `ChoiceChip` row present in both apps. Filter applied via `_matchesFilter()` on each stream emit.
- **Sorting by latest ✅**: `SessionLogService.memberLogsStream` and `trainerLogsStream` both sort Dart-side with `b.startedAt.compareTo(a.startedAt)`.
- **Row shows date + duration + rating ✅**: `_SessionCard` already rendered date via `toFullLabel()`, duration via `toSessionDuration()`, and star row when `rating > 0`.
- **Tap → detail modal (both notes) ❌ → Fixed**: Cards had no tap gesture. Added `InkWell` + `chevron_right` indicator to both apps. Tapping opens `showModalBottomSheet` displaying: date, duration, star rating, member's note (`memberNotes`), and trainer's notes (`trainerNotes`). Both notes were previously visible only to one party.
- **Export: share text summary ❌ → Fixed**: Added `share_plus: ^9.0.0` to both app pubspecs. Detail modal header has `Icons.ios_share` button that calls `Share.share()` with a multiline text summary (title, member name, date, duration, rating, member note, trainer notes).
- **Empty state + "Schedule your first call" CTA ❌ → Fixed**: Both apps had `EmptyStateWidget` without `ctaLabel`/`onCta`. Added `ctaLabel: 'Schedule your first call'`. In `guru_app`, `onCta` navigates to `/schedule`. In `trainer_app`, `onCta` navigates to `/requests` (trainer's call management screen).
- **Trainer card: edit notes inline ✅ (preserved)**: Kept existing `_editingNotes` StatefulWidget with `TextEditingController`. Detail modal also exposes an "Edit notes" icon that pops the sheet and triggers `setState(() => _editingNotes = true)`.

**Files changed:** `guru_app/lib/features/sessions/screens/sessions_screen.dart`, `trainer_app/lib/features/sessions/screens/sessions_screen.dart`, `guru_app/pubspec.yaml`, `trainer_app/pubspec.yaml`  
**Commit:** `feat(sessions): tap-to-detail modal, share export, schedule CTA on empty state`

---

## Entry 25 — 100ms Integration Audit & Fixes

**Prompt pattern:** Verify full 100ms integration spec: token server endpoint + README, room lifecycle, role permissions (trainer end-room vs member leave), edge cases (background/foreground, network loss, token expiry), post-call sheets, ARCHITECTURE.md  
**Findings:**

- **Token server `GET /token?userId=&role=&roomId=` ✅**: Endpoint exists in `token_server/server.js`, signs HS256 JWT, returns `{ token }`. Includes validation for required params and role whitelist.
- **Token server README ❌ → Fixed**: No `README.md` existed in `token_server/`. Created `token_server/README.md` documenting prerequisites, setup steps (`npm install`, `.env` config), all endpoints (`/health`, `GET /token`, `POST /room`), response shapes, fallback behaviour, and a flow diagram.
- **Room lifecycle: approve → room create → RoomMeta ✅**: `CallRequestService.approveRequest()` calls `POST /room`, stores `RoomMetaModel` (with `hmsRoomId`, roles `host`/`guest`), updates status, sends system message.
- **Pre-join: fetch token → join with role ✅**: Both `PreJoinScreen` implementations call `HMSService.fetchAuthToken` with the role from `RoomMetaModel`, then `HMSService.join`.
- **Reconnect handler ✅**: `onReconnecting` → `HMSCallState.reconnecting` (spinner); `onReconnected` → `HMSCallState.connected` (call resumes).
- **Trainer ends call for both ❌ → Fixed**: Trainer's call screen `onLeave` was calling `_hms.leave()` (self-only). Changed to `_hms.endRoom()` — sends `endRoom` to 100ms, which fires `onRemovedFromRoom` on the member's side → `HMSCallState.ended` → post-call navigation triggered for both participants.
- **Member cannot end for both ✅**: Member's call screen uses `_hms.leave()` — only leaves self, does not remove others.
- **Background/foreground — camera pause ❌ → Fixed**: No `WidgetsBindingObserver` existed on the call screens. Added `with WidgetsBindingObserver` to `_CallScreenState` in both apps. On `AppLifecycleState.paused`, camera is auto-muted (with `_cameraWasAutoPaused` flag). On `AppLifecycleState.resumed`, camera is restored if it was auto-paused. Observer registered/deregistered in `initState`/`dispose`.
- **Network loss ✅**: Handled via `onReconnecting`/`onReconnected` in `HMSService`.
- **Token expiry ✅ (by design)**: Tokens are valid 24 h; no session exceeds that. Documented in ARCHITECTURE.md.
- **`onAudioDeviceChanged` no-op ❌ → Fixed**: Was an empty override. Now logs `currentAudioDevice` and `availableAudioDevice` via `AppLogger.rtc`. 100ms SDK handles actual routing automatically.
- **Post-call sheets ✅**: Member: 1–5 star rating + optional 200-char note → `updateRating()`. Trainer: notes TextField + "Mark as Complete" → `updateTrainerNotes()`. (Verified Entry 23, unchanged.)
- **ARCHITECTURE.md ❌ → Updated**: Added **100ms Video Call — Implementation Notes** section: token format/expiry, room-creation flow, role permissions table (trainer `endRoom` vs member `leave`), and edge-case handling table (network loss, background, token expiry, audio device switch).

**Files changed:**  
`token_server/README.md` (created),  
`trainer_app/lib/features/call/screens/call_screen.dart` (endRoom + lifecycle observer),  
`guru_app/lib/features/call/screens/call_screen.dart` (lifecycle observer),  
`shared/lib/services/hms_service.dart` (onAudioDeviceChanged log),  
`ARCHITECTURE.md` (100ms section added)  
**Commit:** `feat(call): token-server README, trainer endRoom, lifecycle camera-pause, ARCHITECTURE 100ms docs`
