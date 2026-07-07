# Feature: Messaging — Better Messages (website's own system)

Covers the website's actual `/messenger/` experience. This is **not** the API the Flutter app uses — see `messaging-buddyboss-rest.md` for that, and the system-split note in `README.md`. Documented here for real-time-feature research and to understand the website's actual behavior as the functional spec.

## Status
- **Website:** Largely confirmed as of the third capture (`.claude/k54global.com3`, 770 entries, 2026-07-07 ~11:15 UTC) — a full conversation walkthrough with a live WebSocket connection, real message send, file upload, audio call, thread pin/unpin, and thread erase all captured with response content. Full endpoint inventory, message/thread schema, and permission model are now documented below. Still open: typing indicators (not observed), video call specifics, and translation-feature usage (field confirmed to exist, not exercised).
- **Flutter:** N/A — the app doesn't use this system directly. JWT-bearer-only compatibility with this API is now confirmed (2026-07-07, both GET and POST tested) — see `implementation-blueprint.md` for the migration plan this unlocks.
- **Figma:** Not yet reviewed.

## ⚠️ Strategic question raised by this capture — partially resolved

Better Messages exposes a **complete, separate REST API** (`/wp-json/better-messages/v1/*`) that covers everything BuddyBoss's own messaging REST API does, plus reactions, translations, per-message favorites, pin/mute/erase, audio/video calling (1:1 and group), and richer permission/friend/block metadata — all documented below. This raises a real question for Phase 2: should the app eventually target *this* API instead of (or in addition to) `/buddyboss/v1/messages`, to get real feature parity with the website?

### JWT-only auth test results (2026-07-07, via curl, outside any browser — no cookies possible) — RESOLVED

| Test | Endpoint | Method | Auth | Result |
|---|---|---|---|---|
| Control | `getFriends` | GET | none | `401 rest_forbidden` — confirms the endpoint is genuinely gated |
| Real test | `getFriends` | GET | `Authorization: Bearer <JWT>` only | **`200 OK`, full data returned** |
| Real test | `checkNew` | POST | `Authorization: Bearer <JWT>` only, raw file-based JSON body (retest after ruling out a PowerShell quoting artifact in the first attempt) | **`200 OK`, full envelope returned** (`threads`, `users`, `messages`, `serverTime`, `currentTime`) |

**Confirmed:** both GET and POST accept JWT-bearer-only authentication on Better Messages' REST API — no WP session cookie, no `X-WP-Nonce`, no browser involved for either test. This resolves the core architectural risk that was blocking a migration recommendation.

**Residual, non-blocking caveat:** this is confirmed for 2 of the ~11 known endpoints. The rest very likely behave the same (a plugin typically wires all its own REST routes through one shared permission-check pattern), but that's an inference from 2 data points, not 11 individually tested — worth one more spot-check on an actual mutating action (e.g. `thread/{id}/send`) at some point, not a blocker to planning.

**Separate and still-unresolved: the WebSocket layer.** JWT/REST compatibility says nothing about whether the app could use `wss://cloud.better-messages.com` — that's a different question entirely, gated on (a) the still-untraced origin of the `sk`/`pdh` handshake values, and (b) the third-party-vendor dependency/ToS consideration already noted. Real-time features (live unread push, read receipts, presence) require the WS layer specifically — the REST API alone only gets you the same polling-based freshness the app already has via `checkNew`. Don't conflate "REST/JWT works" with "real-time works" — see `implementation-blueprint.md`, which keeps these as separate stages.

## Network Behavior

Source: `.claude/k54global.com.har`, 65 entries total, captured 2026-07-07 ~09:57–10:09 UTC.

### Better Messages' own REST endpoint (correction to prior assumption)

`K54_PROJECT_HANDOFF.md` Section 4 described Better Messages as using `admin-ajax.php?action=checkNew`. **That's not what this capture shows.** The actual endpoint is:

```
POST /wp-json/better-messages/v1/checkNew?nocache={timestamp}
Auth: X-WP-Nonce header (e.g. "606c100958") — standard WP REST cookie+nonce, not a POST-field nonce
Content-Type: application/json
Body: {"lastUpdate": <number>, "visibleThreads": [], "threadIds": [16,22,23,28,35,36,37,39,62,64]}
Response: 200, application/json, 68-72 bytes (body not captured), custom header "bbp-unread-messages: 0"
```

So Better Messages **does** have its own proper REST namespace (`/wp-json/better-messages/v1/`), not a pure admin-ajax system as previously assumed. This is now corrected — flagging clearly since the handoff doc states the opposite.

`threadIds` in the request body is the full list of thread IDs the client already knows about (10 threads in this session); `visibleThreads` was empty every time (no open conversation during capture — meaning this array likely tracks which thread(s) are currently open/visible, for read-receipt purposes — inferred, not confirmed, since no conversation was opened during this session).

The `bbp-unread-messages` response header carries the live unread count directly — a lightweight signal available without parsing any response body.

### Polling interval — irregular, not fixed

Timestamps between consecutive `checkNew` calls in this session: ~101s, ~102s, ~61s, ~144s, ~169s, ~89s, ~49s. This is **not** a fixed short interval like the app's 4-second chat polling — it's irregular, ranging roughly 50-170 seconds. Two plausible explanations, neither confirmed: (a) `checkNew` is a long-interval fallback/keep-alive and most real-time delivery actually happens over the WebSocket connection, or (b) the interval is tab-focus-dependent (similar to WP Heartbeat's own focus-based interval, seen below) and this session had visibility/focus changes affecting it. **No conversation was opened during this capture**, so chat-open-triggered request behavior is still completely undocumented.

### WebSocket — confirmed live, full protocol documented

Source: `.claude/k54global.com3`, entry with `_webSocketMessages` (69 frames), captured 2026-07-07 ~11:20-11:34 UTC. **A live WebSocket connection is confirmed** — resolving the open question from the first two captures:

```
wss://cloud.better-messages.com/websocket/?EIO=4&transport=websocket
```

Note the host: this is **Better Messages' own third-party cloud service** (`cloud.better-messages.com`), not `k54global.com` itself — the plugin operates its own hosted real-time relay rather than running a WebSocket server on the site's own infrastructure. Protocol is Engine.IO v4 carrying Socket.IO packets (standard Socket.IO wire format: leading digit(s) indicate packet type — `0`=EIO open, `2`/`3`=EIO ping/pong, `40`=Socket.IO connect, `42`=Socket.IO event, `43x`=ack for request id `x`).

**Handshake / auth:**
```
← 0{"sid":"...","upgrades":[],"pingInterval":25000,"pingTimeout":20000,"maxPayload":100000000}
→ 40{"sid":"k54global.com","uid":5,"sk":"<40-hex-char secret>","v":"2.15.14","pdh":"<hash>"}
← 40{"sid":"<new socket session id>"}
```
`uid` is the WP user ID (5, matches the logged-in test account). `sk` and `pdh` look like a per-session signing key and a page/domain hash respectively — **not traced to a specific issuing request**; they most likely get inlined into the page's initial HTML via `wp_localize_script` (a standard WP pattern for passing server-generated config/secrets to page JS) rather than fetched via a separately observable AJAX call. This is inferred from absence of evidence, not confirmed — flagging the limit of what was traceable rather than guessing further.

**Ping/pong confirmed at the advertised 25s interval** (frames alternate `receive: "2"` / `send: "3"` roughly every 25-26 seconds for the entire idle portion of the session) — standard Engine.IO keep-alive, matches the handshake's `pingInterval: 25000`.

**Events observed (all confirmed from real captured frames, not inferred):**

| Event | Direction | Payload | What it confirms |
|---|---|---|---|
| `subscribeToThreads` | send | array of thread IDs | Client subscribes to specific threads for live updates |
| `groupCallStatusesBulk` | send (ack) | array of thread IDs → ack: `{"<id>": {}, ...}` (empty object = no active call) | **Group calling exists** — bulk call-status check across threads |
| `threadOpen` | send | thread ID | Fired when a conversation is opened; directly observed to trigger the server marking it read (next `getUnread` push drops that thread to 0) |
| `/v3/getStatuses` | send (ack) | array of thread IDs → ack: `[{"thread_id":16,"last_delivered":"...","last_seen":"..."}]` | **Read-receipt/delivery-status mechanism confirmed** — per-thread `last_delivered`/`last_seen` ISO timestamps. Contradicts the original handoff doc's assumption that read receipts are "likely infeasible" — the mechanism is real, just lives on this proprietary WS protocol, not BuddyBoss's REST API. |
| `onlineUsers` | receive | array of user IDs | Real-time presence push (separate delivery path from the Heartbeat-polled `users_presence` snapshot documented in `notifications.md`) |
| `getUnread` | receive (pushed) | `{"total": N, "threads": {"<id>": N, ...}}` | Real-time unread-count push — directly observed dropping to `{"total":0,"threads":{}}` immediately after a `threadOpen` for the thread that had the unread message |
| `threadInfoChanged` | receive | full thread object (see schema below) | Live thread-state sync — observed firing on a pin/unpin toggle (`isPinned` flipped between two consecutive frames for the same thread) |
| `message_deleted` | receive | message ID string | Message deletion pushed live |
| `v2/threadEvent` | receive | `{"thread_id","type":"thread_erased","serverTime","data":[]}` | Generic event envelope — only `"thread_erased"` was observed as a `type` value in this session; other `type` values (e.g. a typing-indicator type) are plausible but **not observed**, don't assume they exist |
| `unsubscribeThread` | send | thread ID | Sent after a thread is erased (observed sent 3× in a row for the same ID — client-side redundancy, not necessarily meaningful) |
| `hostname` | receive | server instance name (e.g. `"bpbm-websocket-2"`) | Infra detail only |

**No typing-indicator event was observed in this session** — absence of evidence, not evidence of absence; a capture that specifically triggers typing (two browser sessions messaging each other live) would be needed to confirm either way.

The sound asset filenames from earlier captures — `notification.mp3`, `sent.mp3`, `calling.mp3`, `dialing.mp3` — are now **strongly corroborated**: `callCreate`/`callMissed` REST endpoints and a `<span class="bpbm-call bpbm-call-audio missed">Missed audio call (00:00)</span>` message were directly observed in this capture (see below).

### Full REST endpoint inventory — note on scope

The full public route index (`GET /wp-json/`, see `rest-route-index.md`) shows **233 routes** under `better-messages/v1` — the table below covers only the ~11 exercised via HAR capture and direct testing. 117 of those 233 are `admin/*` (site-admin config, not app-relevant). The remainder (`ai/*`, `app/*`, `bulkMessages/*`, `search`, `markAllRead`, `getFavorited`, `getUniqueConversation`, the full calling lifecycle beyond `callCreate`/`callMissed`, `blockUser`/`unblockUser`, etc.) are confirmed to **exist** but have no captured request/response yet — see `rest-route-index.md` for the complete list. Treat this table as "deeply verified," not "complete."

### Deeply verified endpoints (request/response captured, `.claude/k54global.com3`)

All under `/wp-json/better-messages/v1/`, `X-WP-Nonce` header auth (same as `checkNew`):

| Endpoint | Method | Request | Response |
|---|---|---|---|
| `checkNew` | POST | `{lastUpdate, visibleThreads, threadIds}` | `{"users":[],"messages":[],"threads":[],"currentTime":<ts>}` — confirmed empty-state shape; same envelope as below when there's something new |
| `threads` | POST | `{"exclude":[<known thread ids>]}` | `{"threads":[...], "users":[...], "messages":[...], "serverTime":<ts>}` — the actual inbox-list-equivalent; "exclude" pattern rather than classic pagination |
| `thread/{id}` | POST | — | `{"threads":[<full thread object>], "users":[...], "messages":[...]}` — full schema below |
| `thread/{id}/send` | POST | `{"message": str, "temp_id": "tmp_{threadId}_{random}", "temp_time": <ts>, "meta": {}}` | not captured (empty body), but the real messages in `thread/{id}`'s response confirm the same `temp_id` reappears on the reconciled message — **confirms an optimistic client-side send pattern**: the website generates its own temp ID/time before the server responds, then reconciles |
| `thread/{id}/upload` | POST | (multipart, not captured in detail) | not captured — endpoint confirmed to exist only |
| `thread/{id}/attachments` | — | — | endpoint path confirmed to exist, not exercised in this capture |
| `thread/{id}/makePinned` | POST | — | `true` (bare boolean) |
| `thread/{id}/unmakePinned` | POST | — | not captured, presumably `true` also |
| `thread/{id}/erase` | POST | — | `true` (bare boolean) |
| `callCreate` | POST | `{"thread_id": id, "type": "audio"}` | not captured — `type` presumably also accepts `"video"`, unconfirmed |
| `callMissed` | POST | `{"thread_id", "type", "message_id", "duration"}` | not captured — `duration: 0` for the missed case observed; ties directly to the "Missed audio call" message that then appears in the thread |
| `getFriends` | GET | — | array of user objects (same shape as `users[]` below) — **all returned entries had `isFriend: 1`**, suggesting the website's "start new conversation" picker may be friends-only, not a general member search (see Functional Behavior — flagged, not fully confirmed) |
| `getGroups` | GET | — | array of `{group_id, name, messages, thread_id, image, url}` — **confirms group chat threads are directly tied to actual BuddyBoss Groups**, sharing the same thread ID numbering as 1:1 threads |

### Confirmed thread + message schema (from `thread/16`, full response captured)

```json
{
  "threads": [{
    "thread_id": 16, "isHidden": 0, "isDeleted": 0, "type": "thread",
    "title": "", "subject": "", "image": "",
    "lastTime": 17834230662434,
    "participants": [2, 5], "participantsCount": 2, "moderators": [],
    "url": "", "meta": {"allowInvite": false},
    "isPinned": 0, "isMuted": false,
    "permissions": {
      "isModerator": true, "deleteAllowed": true,
      "canDeleteOwnMessages": true, "canDeleteAllMessages": true,
      "canEditOwnMessages": true, "canEditAllMessages": true,
      "canFavorite": true, "canMuteThread": true, "canEraseThread": true, "canClearThread": true,
      "canInvite": true, "canLeave": false, "canUpload": true,
      "canVideoCall": true, "canAudioCall": true, "canStartGroupCall": true,
      "canGroupAudio": false, "canGroupVideo": false,
      "canMaximize": true, "canMinimize": true, "canPinMessages": true,
      "canReply": true, "canReplyMsg": [], "requireModeration": false,
      "preventVoiceMessages": false, "canBlockUser": true
    },
    "mentions": [], "unread": 0
  }],
  "users": [
    {"id":"5","user_id":5,"name":"Ezekiel","avatar":"...","url":"https://k54global.com/members/ezekielbamise682gmail-com/",
     "verified":0,"lastActive":"2026-07-07 11:18:46","status":{"slug":"online","icon":"circle","label":"Online"},
     "isFriend":0,"canVideo":1,"canAudio":1},
    {"id":"2","user_id":2,"name":"WISDOM","avatar":"...","url":"https://k54global.com/members/smart/",
     "isFriend":1,"canVideo":1,"canAudio":1,"blocked":0,"canBlock":1}
  ],
  "messages": [
    {"thread_id":16,"sender_id":5,
     "message":"<span class=\"bpbm-call bpbm-call-audio missed\">Missed audio call <span class=\"bpbm-call-duration\">(00:00)</span></span>",
     "created_at":17834230662434,"updated_at":17834230686029,"temp_id":"","message_id":2242,
     "meta":{"reactions":[]},"favorited":0},
    {"thread_id":16,"sender_id":5,"message":"Ignore it please , it is a test",
     "created_at":17834230300210,"temp_id":"tmp_16_912884272","message_id":2241,
     "meta":{"reactions":[],"translations":{},"translationsSkipped":[],"translationsPending":{},"translationPending":false},
     "favorited":0},
    {"thread_id":16,"sender_id":5,"message":"<!-- BM-ONLY-FILES -->",
     "message_id":2240,
     "meta":{"reactions":[],"files":[{"id":1457,"thumb":"https://.../article.webp","url":"https://.../article.webp",
       "mimeType":"image/webp","name":"article.webp","size":97528,"ext":"webp"}]},
     "favorited":0}
  ]
}
```

**New, previously-unknown features this schema confirms:**
- **Message reactions** (`meta.reactions: []` on every message) — an emoji-reaction system exists. Not exercised (always empty in this capture) but the field is real and present on every message.
- **Message translation** (`meta.translations`, `translationsSkipped`, `translationsPending`, `translationPending`) — a live translation feature exists. Not previously known at all, not in any prior documentation. Not exercised in this capture (all empty/false).
- **Per-message favorites** (`favorited: 0` on every message, matches the thread-level `canFavorite` permission) — individual messages can be starred, separate from the whole-thread star some UIs offer.
- **File attachments have a confirmed real schema and storage path**: a file-only message uses the literal string `<!-- BM-ONLY-FILES -->` as its body (a sentinel meaning "no text, just files"), with the real payload in `meta.files[]` (`id`, `thumb`, `url`, `mimeType`, `name`, `size`, `ext`). Storage path: `/wp-content/uploads/bp-better-messages/{yyyy}/{mm}/{dd}/{uuid}/{filename}` — **a dedicated Better-Messages-only media path, not BuddyBoss's own Media component (`bp_media_ids`)**. This means the original handoff doc's caveat about `bp_media_ids` leaking attachments into public activity posts likely doesn't apply to how the website itself handles message attachments — that risk would only resurface if the app implemented attachments via BuddyBoss's own media endpoints directly, a separate path from what the website uses.
- **Missed calls appear as regular messages** with special markup (`<span class="bpbm-call bpbm-call-audio missed">...`) rather than a separate data structure — confirming calling is real and its history is woven directly into the message timeline.
- **`users[]` embedded directly in the thread/inbox response** (avoiding N+1 lookups), each with `isFriend`, `blocked`/`canBlock`, `canVideo`/`canAudio` — relationship and call-permission state is per-user-pair, not a static thread-level flag.
- **Numeric timestamps in these payloads (`created_at`, `lastTime`, etc.) use an unusually large, non-standard format** (14-17 digits, larger than a normal unix-ms epoch) — consistent across every Better Messages payload seen so far. Not reverse-engineered; noted as a known quirk of this plugin's own timestamp encoding, not something to guess the scale of.

### Unread messages also surface via the Heartbeat/notifications payload

Source: `.claude/k54global.com HAR2.har`, entry 0 (`admin-ajax.php`, `action=heartbeat`), captured 2026-07-07 ~09:45 UTC. Full response body present this time (83,781 bytes). Confirmed top-level schema:

```
{
  "users_presence": [{"id": 5, "status": "online"}, {"id": 1, "status": "offline"}, ...],
  "on_screen_notifications": "<html string, 33799 chars>",
  "total_notifications": 58,
  "unread_notifications": "<html string, 35346 chars>",
  "unread_messages": "<html string, 2901 chars>",
  "wp-auth-check": true,
  "server_time": 1783419932
}
```

**This means the website's unread-message indicator is not sourced only from Better Messages' `checkNew` REST endpoint** — it's also carried through this generic Heartbeat payload's `unread_messages` field, which is a rendered HTML fragment, e.g.:
```html
<li class="read-item unread" data-thread-id="3">
  <span class="bb-full-link">
    <a href="https://k54global.com/messenger/?thread_id=3">Re: No Subject</a>
  </span>
  <div class="notification-avatar">
    <a href="https://k54global.com/messenger/?thread_id=3">
      <span class="member-status online" data-bb-user-id="5" data-bb-user-presence="online"></span>
      <img src="https://k54global.com/wp-content/uploads/avatars/...">
```
Not yet understood: whether this and `checkNew` are two redundant signals for the same thing, or serve different UI elements (e.g. this one for a top-nav bell/badge, `checkNew` for the in-page messenger list). Flagging as an open question, not resolving by guessing.

**Messenger deep-link URL format confirmed:** `https://k54global.com/messenger/?thread_id={id}` — a query parameter, appearing twice independently in this one payload (once in `on_screen_notifications`, once in `unread_messages`). This is now more strongly evidenced than the hash-route form (`/messenger/#/conversation/{id}`) mentioned when the SPA routing behavior was first described — both may be valid (the query param could be a server-generated deep link the SPA's router picks up and translates into its own hash-route on load), but this is the format the server itself actually generates, so treat it as the primary confirmed one until proven otherwise.

**Presence feature confirmed with a real shape:** `users_presence` is an array of `{id, status}` objects, `status` being `"online"`/`"offline"` strings — not gated behind messaging specifically, this came through the general heartbeat, and the presence indicator (`data-bb-user-presence="online"`) also appears inline on message notification HTML. Not implemented anywhere in the app currently.

**Notification content examples confirmed** (real, not fabricated — from the actual payload): a message notification ("Ezekiel sent you a message: \"did it get there\"") linking to the `?thread_id=` format above, and an activity-post notification ("Ezekiel posted an update: \"GOOD MORNING EVERYONE 🙏\"") linking to `https://k54global.com/news-feed/p/{id}/?rid={id}` — a different, confirmed URL pattern for activity-item deep links. See `notifications.md` for the full notifications-feature writeup this payload also feeds.

**Member profile URL uses a slug, not a numeric ID:** `https://k54global.com/members/ezekielbamise682gmail-com/` (slugified from the account's email). `lib/models/post_model.dart:140` currently builds `profileLink` as `https://k54global.com/members/${user_id}` (bare numeric ID) — whether that URL actually resolves on the live site is unconfirmed (BuddyBoss may accept both forms), not asserted as broken, but now a concrete thing worth verifying rather than assuming is fine.

### Legacy admin-ajax.php actions observed (not messaging, but same session — see note below)

- `action=heartbeat` — WP core Heartbeat API, used here by BuddyPress for live activity-feed updates (see `activity-feed.md`) and by other plugins piggybacking the same mechanism.
- `action=members_filter`, `action=groups_filter`, `action=groups_join_group` — see `members.md` / `groups.md` (to be created) — these belong to those features, not messaging, but appeared in the same capture session since the user also browsed Members/Groups. **Important generalization** for the whole audit: the website's own UI relies on legacy `admin-ajax.php` actions (BuddyPress/BuddyBoss's classic AJAX system, auth via a POST-field nonce, not the `X-WP-Nonce` header) for Members and Groups, exactly like it does for messaging (Better Messages) rather than the REST API. This is not messaging-specific — expect the same "website uses legacy AJAX, app must use REST" split for every remaining feature area. Updated in `README.md`'s system-split section.

Auth pattern comparison confirmed from this capture:
- REST endpoints (`/wp-json/...`) → `X-WP-Nonce` request header.
- Legacy AJAX (`admin-ajax.php`) → nonce passed as a POST body field (name varies: `nonce`, `_nonce`, `_wpnonce` depending on the action/plugin), verified via `check_ajax_referer` server-side. Every admin-ajax call in this capture also carried a `_tutor_nonce` field regardless of action — Tutor LMS's JS appears to attach its nonce globally to every AJAX request site-wide, unrelated to the action being performed.

### Unrelated traffic identified and filtered out

`message-hub.hostinger.com` (`/api/v2/public/init`, `/api/v2/public/outreach`) — Hostinger's own AI website-assistant widget (matches the "Hostinger AI"/"Hostinger Reach" plugins). Not BuddyBoss/Better Messages/K54-related. `hostinger-ai-assistant` REST routes on `k54global.com` itself are the same thing. Excluded from further messaging documentation.

## Functional Behavior

**Business rules (confirmed from real traffic):**
- Opening a conversation (`threadOpen` WS event) is what marks it read — directly observed: the `getUnread` push dropped from `{"total":1,"threads":{"23":1}}` to `{"total":0,"threads":{}}` immediately after `threadOpen` was sent for thread 23.
- Sending is **optimistic** on the website: a `temp_id`/`temp_time` pair is generated client-side before the server responds, then reconciled against the real `message_id` once the server confirms (confirmed by the `send` request shape and by real messages in `thread/16`'s response still carrying their original `temp_id`). This is the opposite of the Flutter app's current `ChatController.send()`, which waits for the server response before showing anything — already flagged as a possible improvement in the original handoff doc; now confirmed as literally how the website behaves, not just a hypothetical nicety.
- **Possible business rule, not fully confirmed:** `getFriends` returned only entries with `isFriend: 1`. If this is genuinely the data source for the website's "start new conversation" picker, the website may restrict starting new conversations to friends only — a real, potentially significant difference from the Flutter app's `NewConversationPage`, which searches *all* members via `/buddyboss/v1/members?search=`, not just friends. Flagging as a likely gap, not asserting it with full certainty — would need to observe the actual "new conversation" UI action, not just this one endpoint call in isolation.
- Group messaging threads are directly tied to real BuddyBoss Groups (`getGroups` response ties `group_id` to a `thread_id` in the same numbering space as 1:1 threads) — group chat isn't a separate concept from BuddyBoss Groups, it's the group's own dedicated thread.

**Permission model (confirmed, full field list in the schema above):** every thread carries a rich per-user permission object — moderator status, delete (own/all messages), edit (own/all), favorite, mute, erase/clear thread, invite, leave, upload, video/audio call (1:1 and group), pin messages, reply, block user, plus thread-level flags (`requireModeration`, `preventVoiceMessages`). **None of this permission model exists in the Flutter app currently** — the app's messaging has no concept of moderation, muting, pinning, blocking, or differentiated per-user capability at all.

**State machine additions beyond what the app currently models:** thread state now confirmed to include `isPinned`, `isMuted`, `isHidden`, `isDeleted` — the app's `MessageThread` model has none of these.

**Client-side logic not obvious from the API:** the optimistic temp-ID pattern (above) is entirely client-side bookkeeping; the server has no concept of a "pending" message, it just returns the real message once created and the client matches it back to its temp entry.

**Edge cases / unusual behavior observed:** the numeric timestamp format anomaly (noted above); `unsubscribeThread` sent 3 times in a row for the same thread ID after an erase (client-side redundancy — not necessarily a bug, could be intentional retry-for-reliability).

## Role / Account-Status Variations

Not tested — single account/role only. The confirmed `permissions` object above (`isModerator: true` for this account in a 2-person thread) suggests moderator status may be assignable per-thread rather than being a site-wide role — worth testing with a second, non-moderator account before assuming the permission model varies by *site role* rather than *per-thread* assignment.

## Undocumented / Plugin-Specific Behavior

- `sk`/`pdh` WebSocket auth values — traced as far as possible (see WebSocket section); most likely inlined via `wp_localize_script` at page load, not confirmed by a directly observable request.
- Video calling — `callCreate`'s `type` field confirmed to accept `"audio"`; whether `"video"` is a valid value wasn't directly observed (only inferred from the `canVideoCall` permission and unused `calling.mp3`/related assets) — plausible, not confirmed.
- Group audio/video calling — permission flags (`canGroupAudio`, `canGroupVideo`, `canStartGroupCall`) exist and were `false`/`true` respectively for this thread type (2-person, so group-call flags being false makes sense) — not observed in an actual group thread.
- `v2/threadEvent`'s other possible `type` values beyond the one observed (`"thread_erased"`) — not traced further.

## Open Questions

- ~~Does `getFriends`/`checkNew` work with JWT-bearer-only auth?~~ **Confirmed yes for both** (2026-07-07 curl tests, GET and POST). Residual: not individually tested on the other ~9 endpoints known from HAR capture.
- ~~Do AI conversations exist in this system?~~ **Correction — yes, confirmed.** The full REST route index (`GET /wp-json/`, see `rest-route-index.md`) shows a real `better-messages/v1/ai/*` namespace (8 routes: bot welcome messages, response generation/cancellation, message moderation, voice transcription, message translation) plus `getAIBots`. My earlier statement that there was no evidence for this was accurate for what we'd captured, not evidence it doesn't exist — corrected here. Full route paths are in `rest-route-index.md`; none have been exercised yet (no request/response body captured for any of them).
- **New lead, not yet investigated:** `better-messages/v1/app/*` (`login`, `savePushToken`, `getSettings`, `syncScripts`) looks like an **official, dedicated mobile-app integration path** — potentially a better migration target than reusing the general JWT-bearer approach, especially for real push notifications instead of polling. See `rest-route-index.md` and the updated `implementation-blueprint.md`. Needs its own investigation (what does `app/login` expect/return? does it supersede or complement the JWT approach already confirmed working?) before the blueprint's recommended approach is finalized.
- Is the friends-only restriction on new-conversation starting real, or was this account's `getFriends` call just for a different UI purpose (e.g. a "quick access" list, not the actual full picker)?
- Full `upload`/`attachments` endpoint request/response shapes — confirmed to exist, not captured in detail.
- Typing indicators — still not observed in any capture so far.
- Does `callCreate` truly support `type: "video"`, and what does a full call lifecycle (create → ring → answer/miss → end) look like end-to-end?
- What do the other permission-model fields look like for a non-moderator participant, or in a group thread?

## Next capture needed

A second simultaneous session (two browser profiles/devices messaging each other) would directly confirm typing indicators and give a non-self perspective on read receipts/delivery status.

## Discrepancy Log

Covers both `messaging-better-messages.md` and `messaging-buddyboss-rest.md` — one feature, two files.

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Better Messages' transport mechanism | `K54_PROJECT_HANDOFF.md`: "uses `admin-ajax.php?action=checkNew`" | HAR1 (2026-07-07): `checkNew` is a real REST route, `/wp-json/better-messages/v1/checkNew`, not admin-ajax | **Documentation Drift** |
| 2 | "AI conversations" existence | This audit's own earlier statement (same session): "no evidence for AI conversations in any capture" | Full REST route index: `better-messages/v1/ai/*` (8 routes) + `getAIBots` confirmed real | **Documentation Drift** (self-correction) — the earlier statement was accurate for what had been captured at the time, not a claim the feature doesn't exist; recorded so the correction is traceable, not silently absorbed |
| 3 | `recipients` field shape | Model code assumed `List<dynamic>?` | Live payload: `recipients` is a `Map<String,dynamic>` keyed by user ID | **Confirmed Bug** (fixed this session) |
| 4 | Wrong participant shown in every thread | N/A — undocumented until found | `other?['id']` (recipient-row ID) was compared against `currentUserId` (WP user ID) instead of `other?['user_id']` — always failed to match, defaulted to first recipient | **Confirmed Bug** (fixed this session) |
| 5 | `ChatController`/`InboxController` disposal crash | N/A | `notifyListeners()` called unconditionally after an await that could outlive the widget | **Confirmed Bug** — `ChatController` fixed this session; **`InboxController` has the identical bug, found by code review, not yet fixed** (still open) |
| 6 | Chat send optimism | No documented expectation either way | Website confirmed optimistic (client-generated `temp_id`/`temp_time`, reconciled later); app's `ChatController.send()` waits for server response | **Technical Debt** / **Architectural Opportunity** — not wrong, just behind the confirmed reference behavior; logged in `architecture-recommendations.md` |
| 7 | JWT auth compatibility with Better Messages | Assumed to be a blocking risk (nonce tied to cookie session) | Directly tested: GET and POST both work JWT-bearer-only, no cookie/nonce | **Architectural Opportunity** — removes a blocker, doesn't fix a defect |

## Parity Scorecard

**Capability list this score is computed from** (24 distinct user-facing capabilities, derived from the confirmed Better Messages REST + WebSocket surface): send message, receive/view thread, inbox list, mark read, start new conversation, search/pick recipient, reactions, translations, per-message favorites, pin thread, mute thread, erase thread, block/unblock user, audio call, video call, group calling, file/image attachments, AI bots in chat, voice transcription, message search, read receipts, presence indicators, push notifications, group chat tied to BuddyBoss groups.

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **6 of 24 implemented** (send [non-optimistic], receive/view, inbox list, mark read, start new conversation, search/pick recipient) = **25%**
- **Parity:** 25%
- **Confirmed Bugs:** 1 currently open (`InboxController` disposal crash — `ChatController`'s twin was fixed this session, so not double-counted here)
- **Missing Features:** 14 (reactions, translations, per-message favorites, pin, mute, erase-via-Better-Messages, block/unblock, audio/video/group calling, AI bots, voice transcription, message search, read receipts, presence, push notifications)
- **Decorative UI:** 0 — every messaging screen element that exists is wired to real (BuddyBoss) functionality; nothing found here resembles Activity Feed's placeholder buttons
- **API Coverage:** **against Better Messages specifically, ~0%** — the app calls none of its ~40 thread-relevant routes directly (by design, per the current staged blueprint); the app instead achieves overlapping capability via a *different* API (`buddyboss/v1/messages`, ~5 of 7 routes used). Reporting both numbers rather than one blended figure, since collapsing them would hide the real architectural gap (not using the website's actual system) behind the smaller functional gap (basic messaging still works via another route).
- **Evidence Confidence:** ✅ ~12 (JWT GET+POST tests, full WS protocol with 69 real frames, thread/message schema from a real captured response, calling confirmed invoked, pin/erase confirmed invoked, both parsing bugs and the disposal bug) / 🟡 ~4 (video call type, mute action, `app/*` mobile integration, individual endpoint-by-endpoint JWT compatibility beyond the 2 tested) / 🔴 ~5 (`ai/*` behavior, error response shapes, typing indicators, `sk`/`pdh` provisioning source, friends-only restriction) → **(12 + 2)/21 ≈ 67%**. Reasoned tally, not a precise instrument.
