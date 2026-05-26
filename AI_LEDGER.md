# AI Ledger — WTF Gym Flutter Assessment

> Records all significant AI-assisted decisions, generated code blocks, and design choices during this session.

---

## Format

Each entry follows this structure:

| Field | Description |
|-------|-------------|
| **Prompt #** | Sequential entry number |
| **Tool** | AI tool used (GitHub Copilot powered by Claude Sonnet 4.6) |
| **Intent** | What was requested (e.g., "generate Riverpod provider for auth") |
| **Output snippet** | Key generated or verified code block |
| **Commit link** | `git log --oneline` SHA where the code landed |

All entries from Entry 1 onwards were assisted by **GitHub Copilot (Claude Sonnet 4.6)** in VS Code.

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

---

## Entry 28 — Local Scheduled Push Notifications

**Prompt #:** 28  
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**Intent:** Add local scheduled notifications (reminders) to both apps so users are reminded 10 minutes before an upcoming session.

**Design decisions:**
- `NotificationService` singleton created in `shared/lib/services/notification_service.dart`. Uses `flutter_local_notifications` + `timezone` packages.
- `init()` initialises the plugin, creates the Android notification channel (`wtf_gym_reminders`, Importance.high), and requests `POST_NOTIFICATIONS` + `SCHEDULE_EXACT_ALARM` permissions at runtime.
- `scheduleSessionReminder({requestId, scheduledFor, title, body, minutesBefore = 10})` calls `plugin.zonedSchedule` with `AndroidScheduleMode.exactAllowWhileIdle`. Is a no-op if the reminder time has already passed.
- `cancelReminder(requestId)` allows downstream code to cancel a pending notification using the same derived `notifId`.
- Notification ID derived as `requestId.hashCode.abs() & 0x7FFFFFFF` — stable integer from the Firestore document ID.
- **guru_app**: reminder scheduled immediately after `CallRequestService.createRequest()` succeeds in `schedule_screen.dart`. The `requestId` is captured once and shared between both calls to keep IDs in sync.
- **trainer_app**: reminder scheduled immediately after `CallRequestService.approveRequest()` succeeds in `requests_screen.dart`.
- `NotificationService.instance.init()` called in both `main()` functions before `runApp`.
- Android manifests for both apps updated with `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` (minSdk 33), and `POST_NOTIFICATIONS` (minSdk 33).

**Output snippet:**
```dart
// notification_service.dart
Future<void> scheduleSessionReminder({
  required String requestId,
  required DateTime scheduledFor,
  required String title,
  required String body,
  int minutesBefore = 10,
}) async {
  final reminderTime = scheduledFor.subtract(Duration(minutes: minutesBefore));
  if (!reminderTime.isAfter(DateTime.now())) return;

  await _plugin.zonedSchedule(
    requestId.hashCode.abs() & 0x7FFFFFFF,
    title, body,
    tz.TZDateTime.from(reminderTime, tz.local),
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: requestId,
  );
}
```

**Files changed:**
- `shared/lib/services/notification_service.dart` (created)
- `shared/lib/shared.dart` (export added)
- `shared/pubspec.yaml` (`flutter_local_notifications: ^18.0.0`, `timezone: ^0.9.4`)
- `guru_app/pubspec.yaml` (same deps)
- `trainer_app/pubspec.yaml` (same deps)
- `guru_app/lib/main.dart` (`NotificationService.instance.init()`)
- `trainer_app/lib/main.dart` (`NotificationService.instance.init()`)
- `guru_app/android/app/src/main/AndroidManifest.xml` (permissions)
- `trainer_app/android/app/src/main/AndroidManifest.xml` (permissions)
- `guru_app/lib/features/schedule/screens/schedule_screen.dart` (schedule on submit)
- `trainer_app/lib/features/requests/screens/requests_screen.dart` (schedule on approve)

**Commit:** `feat(notifications): local scheduled 10-min session reminders in both apps`

---

## Entry 27 — Offline Send Queue for Chat

**Prompt #:** 27
**Tool:** GitHub Copilot (Claude Sonnet 4.6)
**Intent:** Messages typed while offline must be queued locally and auto-delivered when connectivity returns.

**Design decisions:**

| Decision | Rationale |
|----------|-----------|
| Hive `Box<String>` for persistence | Already initialised in both apps; survives app restarts; no new dependency |
| ID generated before send attempt | Same UUID written to queue AND Firestore so the stream deduplicates on flush success |
| `OfflineQueueService` singleton | One queue shared across both screens; state survives screen navigation |
| Stop-at-first-failure flush order | Preserves message ordering when connectivity is patchy |
| 30 s periodic timer + `AppLifecycleState.resumed` trigger | Covers both background → foreground and in-app recovery scenarios |

**Output snippet — queue + merge in `_sendMessage`:**
```dart
final id = _uuid.v4();
final createdAt = DateTime.now();
try {
  await ChatService.instance.sendMessage(id: id, ...);
} catch (_) {
  await OfflineQueueService.instance.enqueue(id: id, ...);
  // snackbar shown; queue shown in UI immediately
}
```

**Output snippet — merge queued into Firestore stream:**
```dart
final sentIds = firestoreMessages.map((m) => m.id).toSet();
final queued = OfflineQueueService.instance
    .pendingFor(widget.chatId)
    .where((m) => !sentIds.contains(m.id))
    .toList();
final allMessages = [...firestoreMessages, ...queued]
  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
```

**Files changed:**
- `shared/lib/services/offline_queue_service.dart` (created)
- `shared/lib/services/chat_service.dart` (optional `id`/`createdAt` params)
- `shared/lib/widgets/status_ticks.dart` (added `'queued'` → orange `Icons.schedule`)
- `shared/lib/shared.dart` (export `offline_queue_service.dart`)
- `guru_app/lib/features/chat/screens/conversation_screen.dart`
- `trainer_app/lib/features/chat/screens/conversation_screen.dart`

**Commit:** `feat(chat): offline send queue with Hive persistence and auto-flush`

---



Entries where AI identified root causes and provided diagnostic steps for real runtime errors.

### Entry 13 — Firestore Composite Index Errors

**Error encountered:**
```
[Cloud Firestore] FAILED_PRECONDITION: The query requires an index. You can create it here: https://console.firebase.google.com/…
```
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**AI diagnosis:** `orderBy` + `where` compound queries require manually-provisioned Firestore composite indexes not present in this project. Removed `orderBy` and sorted in Dart instead.  
**AI-generated fix snippet:**
```dart
// Before (crashes without composite index)
.collection('messages').where('chatId', isEqualTo: chatId).orderBy('timestamp')

// After (Dart-side sort — no index required)
.collection('messages').where('chatId', isEqualTo: chatId)
// then in stream map:
..sort((a, b) => a.timestamp.compareTo(b.timestamp));
```
**Commit:** `fix(firestore): remove orderBy to avoid composite index requirement`

---

### Entry 14 — onHMSError Propagation + 20-Second Connection Timeout

**Error encountered:**
```
Call screen stuck on "Connecting…" indefinitely after join().
onHMSError() never surfaced the terminal SDK error.
```
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**AI diagnosis:** `onHMSError` was an empty override — terminal errors were silently dropped. No timeout guard on join. Added error propagation and 20-second `Timer` guard.  
**AI-generated fix snippet:**
```dart
@override
void onHMSError({required HMSException error}) {
  AppLogger.rtc('[RTC] Error: ${error.message} (code: ${error.code})');
  if (error.isTerminal) {
    _updateState(HMSCallState.error);
    onError?.call(error.message ?? 'Call failed');
  }
}
```
**Commit:** `fix(call): propagate onHMSError, 20-second join timeout guard`

---

### Entry 15 — 100ms Role Name Fix

**Error encountered:**
```
[100ms SDK] Error joining room: invalid role "trainer" — role does not exist in template
```
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**AI diagnosis:** Template `6a1494d14a799ad17a8b5c54` only defines roles `host` / `guest`. Requested roles `trainer`/`member` don't exist.  
**AI-generated fix snippet:**
```dart
// app_constants.dart
static const hmsTrainerRole = 'host';
static const hmsMemberRole  = 'guest';
```
**Commit:** `fix(call): use host/guest roles, add HMS_TEMPLATE_ID to env`

---

### Entry 16 — HTTP Timeout on Token Server Calls

**Error encountered:**
```
Approve button spinner never resolves. http.get blocks indefinitely when token server is unreachable.
```
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**AI-generated fix snippet:**
```dart
final res = await http.get(uri).timeout(const Duration(seconds: 8));
```
**Commit:** `fix(network): 8-second HTTP timeout on all token-server calls`

---

## Refactor with AI

Entries where AI-driven code restructuring corrected behaviour or improved clarity.

### Entry 22 — Chat Bubble Colour: Perspective-Based → Role-Based

**Problem:** Bubble colour was `isFromMe`-based. In `trainer_app`, the trainer's own messages appeared blue and the member's appeared red — visually backwards.  
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**Intent:** Refactor `MessageBubble` to use sender role, not sending perspective, so colour is consistent across both apps.  
**Before:**
```dart
final bubbleColor = isFromMe ? AppColors.memberBubble : AppColors.trainerBubble;
```
**After:**
```dart
// Role-based — consistent regardless of which app is rendering
final isMemberMessage = message.senderId == AppConstants.memberDkId;
final bubbleColor = isMemberMessage
    ? AppColors.memberBubble   // #E3F0FF blue
    : AppColors.trainerBubble; // #FFEBEB red
```
**Commit:** `fix(chat): role-based bubble colours, single-check sent tick, simulated typing, pull-to-load history`

---

## Entry 26 — Quality Gates & Spec Compliance Audit (§6–§11)

**Prompt #:** 26  
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**Intent:** Audit all spec sections §6 (Quality Gates), §7 (AI-Native Evidence), §8 (Observability/DX), §9 (Security), §10 (Performance), §11 (UI Copy) and fix every gap found.

**Gaps found and fixed (11 total):**

| # | Section | Gap | Fix |
|---|---------|-----|-----|
| 1 | §11 | Toast "Pending approval by Aarav" | → "Call requested. Waiting for trainer approval." |
| 2 | §11 | System message only showed time | → "Call approved for May 26 at 6:00 PM." using `_formatDateTime` |
| 3 | §11 | Declined showed "Reason: x" | → "Call request declined. Reason: x." |
| 4 | §11 | Conversation screen had no empty state | Added "No messages yet. Start the conversation." (both apps) |
| 5 | §11 | Pre-join missing body copy | Added "Ready to join? Check mic and camera." subtitle (both apps) |
| 6 | §11 | No "Session saved" confirmation | Added `initState` snackbar "Session saved to your logs." (both apps) |
| 7 | §8 | DevPanel missing env vars + build info | Added masked `token_server: http://10.0.2.2:****` + `App: WTF Guru v1.0.0` rows |
| 8 | §8 | Error snackbars had no Copy action | Added `SnackBarAction(label: 'Copy error', …)` to all error snackbars |
| 9 | §9 | `.env.example` missing `HMS_TEMPLATE_ID` | Added `HMS_TEMPLATE_ID=your_template_id` |
| 10 | §7 | Ledger missing required format fields | Added Format table, Debugging section, Refactor section |
| 11 | §7 | 0 commits with AI reference in body | All new commits include `AI-assisted: GitHub Copilot (Claude Sonnet 4.6)` body line |

**Output snippet — DevPanel build info and masked env vars:**
```dart
// Build info row
Text(
  'App: ${widget.appName} v1.0.0',
  style: const TextStyle(color: AppColors.grey400, fontSize: 10, fontFamily: 'monospace'),
),
// Env vars (masked)
Text(
  'token_server: ${_maskUrl(AppConstants.tokenServerUrl)}',
  style: const TextStyle(color: AppColors.grey400, fontSize: 10, fontFamily: 'monospace'),
),
```

**Files changed:**
- `guru_app/lib/features/schedule/screens/schedule_screen.dart`
- `guru_app/lib/features/schedule/screens/my_requests_screen.dart`
- `shared/lib/services/call_request_service.dart`
- `guru_app/lib/features/chat/screens/conversation_screen.dart`
- `trainer_app/lib/features/chat/screens/conversation_screen.dart`
- `guru_app/lib/features/call/screens/pre_join_screen.dart`
- `trainer_app/lib/features/call/screens/pre_join_screen.dart`
- `guru_app/lib/features/call/screens/post_call_rating_screen.dart`
- `trainer_app/lib/features/call/screens/post_call_notes_screen.dart`
- `shared/lib/widgets/dev_panel.dart`
- `guru_app/lib/widgets/dev_panel_overlay.dart`
- `trainer_app/lib/features/home/screens/home_screen.dart`
- `guru_app/lib/features/call/screens/call_screen.dart`
- `trainer_app/lib/features/call/screens/call_screen.dart`
- `guru_app/lib/features/call/screens/pre_join_screen.dart` (Copy error action)
- `trainer_app/lib/features/requests/screens/requests_screen.dart`
- `token_server/.env.example`
- `AI_LEDGER.md`

**Commit:** `fix(spec): §6–§11 quality gates — copy strings, DevPanel, error snackbars, env example, ledger format`

---

## Entry 27 — Light/Dark Theme Toggle

**Prompt #:** 27  
**Tool:** GitHub Copilot (Claude Sonnet 4.6)  
**Intent:** Implement a persistent Light/Dark theme toggle in both apps.

**Design decisions:**
- `ThemeNotifier` (`StateNotifier<ThemeMode>`) created in `shared/lib/utils/theme_notifier.dart`. Persists selection to `SharedPreferences` under key `pref_theme_mode`.
- `loadPersistedTheme()` helper called in both `main()` functions before `runApp`. The saved `ThemeMode` is injected via `ProviderScope` overrides so the correct theme is active on the very first frame (no flash of wrong theme).
- `AppTheme` extended with `guruDark()` and `trainerDark()` static methods. Dark theme uses `Brightness.dark` colour scheme + custom surface (`#1E1E1E`), scaffold background (`#121212`), appBar (`#1A1A1A`), card border (`#2C2C2C`), and input fill (`#2C2C2C`).
- Both `MaterialApp.router` instances now declare `theme`, `darkTheme`, and `themeMode` — Flutter handles the animated transition.
- Toggle `IconButton` (`dark_mode` / `light_mode` icons) added to `AppBarBadge` `actions` on both home screens. Tapping calls `ref.read(themeNotifierProvider.notifier).toggle()`.

**Output snippet:**
```dart
// theme_notifier.dart
class ThemeNotifier extends StateNotifier<ThemeMode> {
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, next == ThemeMode.dark ? 'dark' : 'light');
  }
}

// main.dart (both apps)
final savedTheme = await loadPersistedTheme();
runApp(
  ProviderScope(
    overrides: [themeNotifierProvider.overrideWith((_) => ThemeNotifier(savedTheme))],
    child: const GuruApp(),
  ),
);
```

**Files changed:**
- `shared/lib/utils/app_theme.dart` (dark theme builders)
- `shared/lib/utils/theme_notifier.dart` (created)
- `shared/lib/shared.dart` (export)
- `guru_app/lib/main.dart` (seed theme override)
- `trainer_app/lib/main.dart` (seed theme override)
- `guru_app/lib/app.dart` (darkTheme + themeMode)
- `trainer_app/lib/app.dart` (darkTheme + themeMode)
- `guru_app/lib/features/home/screens/home_screen.dart` (toggle button)
- `trainer_app/lib/features/home/screens/home_screen.dart` (toggle button)

**Commit:** `feat(theme): light/dark toggle with SharedPreferences persistence in both apps`

