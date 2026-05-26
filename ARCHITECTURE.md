# Architecture

## Overview

Two standalone Flutter apps share a local Dart package (`shared/`) and a Node.js token server. They communicate via Firebase Firestore in real time and conduct video calls via 100ms.

```
┌───────────────────────────────────────────────────────────────┐
│                        Android Emulator(s)                    │
│                                                               │
│  ┌─────────────┐         ┌──────────────┐                    │
│  │  guru_app   │         │ trainer_app  │                    │
│  │  (member)   │         │  (trainer)   │                    │
│  └──────┬──────┘         └──────┬───────┘                    │
│         │ depends on            │ depends on                 │
│         └──────────┐   ┌────────┘                            │
│                    ▼   ▼                                      │
│              ┌──────────────┐                                 │
│              │   shared/    │                                 │
│              │  (Dart pkg)  │                                 │
│              └──────┬───────┘                                 │
│                     │                                         │
└─────────────────────┼─────────────────────────────────────────┘
                      │
          ┌───────────┼──────────────────────────┐
          ▼           ▼                          ▼
   Firebase       100ms.live             token_server
   Firestore      (video SDK)            (Node.js :3000)
```

---

## shared/ package

| Layer    | Files                                                                                                                               |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Models   | `user_model`, `message_model`, `call_request_model`, `session_log_model`, `room_meta_model`                                         |
| Services | `auth_service` (SharedPrefs), `user_service`, `chat_service`, `call_request_service`, `session_log_service`, `hms_service`          |
| Widgets  | `app_bar_badge`, `message_bubble`, `typing_indicator`, `status_ticks`, `time_chip`, `empty_state_widget`, `cta_button`, `dev_panel` |
| Utils    | `app_theme`, `app_logger`, `app_constants`, `validators`, `date_extensions`                                                         |

---

## State Management

Riverpod `Provider` (no code-gen) is used for router injection. All real-time data is driven by Firestore `StreamBuilder`s directly in screens — no extra providers needed for reactive data.

---

## Real-time Chat

```
sendMessage()
  → Firestore batch write:
      chats/{chatId}/messages/{msgId}   (MessageModel)
      chats/{chatId}                    (ChatMeta: lastMessage, unreadCount++)
markAsRead()
  → chats/{chatId}.unreadCount[userId] = 0
  → messages where status != 'read' → status = 'read'
setTyping()
  → typing/{chatId}_{userId}.isTyping = true/false, timestamp
typingStream()
  → stale if >5 sec old → returns false
```

---

## Video Call Flow

```
Trainer approves request
  → POST /room  to token_server
  → 100ms room created via Management API
  → RoomMeta stored in Firestore (room_metas/{requestId})
  → call_requests/{id}.status = 'approved'
  → system message sent in chat

Member/Trainer open PreJoinScreen
  → getRoomMetaForRequest()   → fetches hmsRoomId
  → GET /token?userId=&role=&roomId=   → JWT from token_server
  → HmsService.join(authToken)

CallScreen
  → HMSVideoView for local (PiP) and remote peers
  → leave() → SessionLogService.createLog()
  → navigate to post-call screen
```

---

## Firestore Collections

| Collection                | Purpose                                              |
| ------------------------- | ---------------------------------------------------- |
| `users`                   | UserModel (id, name, email, role, assignedTrainerId) |
| `chats/{chatId}`          | ChatMeta (lastMessage, unreadCounts, names)          |
| `chats/{chatId}/messages` | MessageModel                                         |
| `call_requests`           | CallRequestModel                                     |
| `room_metas`              | RoomMetaModel (hmsRoomId per request)                |
| `session_logs`            | SessionLogModel                                      |
| `typing`                  | `{chatId}_{userId}` typing presence documents        |
