# Technical Decisions

## D-01: Shared Dart Package

**Decision:** Extract all models, services, and widgets into `shared/` local package.  
**Rationale:** Avoid duplication; both apps use identical data models and Firestore service logic. Local path dependency means no pub.dev publishing required.

---

## D-02: Firestore as Real-time Backend

**Decision:** Use Cloud Firestore for chat, call requests, and session logs.  
**Rationale:** Firebase was pre-configured in the project. Firestore's `snapshots()` streams map cleanly to Flutter's `StreamBuilder`. Alternative (raw sockets / WebSockets) would require a separate server.

---

## D-03: Riverpod without Code Generation

**Decision:** Use `flutter_riverpod` with manual `Provider` declarations.  
**Rationale:** Assessment timeframe doesn't warrant the build_runner overhead. Only the GoRouter is injected via a Provider; all other state is Firestore streams.

---

## D-04: Mock Auth via SharedPreferences

**Decision:** No Firebase Auth; store userId/role in SharedPreferences via `AuthService`.  
**Rationale:** The seeded user IDs (`member_dk`, `trainer_aarav`) are fixed. Real email/password auth adds Firebase Auth config complexity without assessment value.

---

## D-05: 100ms for Video

**Decision:** Use `hmssdk_flutter` + a local Node.js token server.  
**Rationale:** 100ms provides a Flutter SDK with HMSVideoView. The token server generates HS256 JWTs locally (no round-trip to 100ms token endpoint required for development). Management token is used to create rooms via the 100ms REST API.

---

## D-06: go_router for Navigation

**Decision:** Declarative `GoRouter` with path parameters for callRequestId / sessionLogId.  
**Rationale:** Deep-link capable; path parameters cleanly pass IDs between screens without needing extra state.

---

## D-07: flutter_animate for Motion

**Decision:** Use `flutter_animate` for entrance animations on cards and success icons.  
**Rationale:** Zero-boilerplate declarative animations that work without AnimationController setup.

---

## D-08: No TypeAdapters for Hive

**Decision:** Store only simple strings (userId, role) in Hive; no custom TypeAdapters.  
**Rationale:** Firestore is the source of truth. Hive is used only for session persistence (like "who is logged in"). Avoids code-gen dependency.

---

## D-09: chatId Format

**Decision:** `sorted([uid1, uid2]).join('_')` as the canonical chat document ID.  
**Rationale:** Deterministic, collision-free, works from either side of the conversation without an extra lookup.

---

## D-10: Token Server Fallback

**Decision:** `POST /room` returns a synthetic `local_{name}` ID if the 100ms API is unreachable.  
**Rationale:** Allows offline testing of the approval flow and navigation without a live 100ms project configured.
