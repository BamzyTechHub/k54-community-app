# Implementation Blueprint (Phase 2 planning — nothing here is implemented)

Grows alongside the audit: one section per feature, added once that feature has enough confirmed evidence to plan against. Deliberately separate from two adjacent files:
- `gap-analysis.md` — *what* differs between website/Figma/app (the problem statement).
- `architecture-recommendations.md` — reuse/consolidation opportunities noticed while documenting, kept separate on purpose so "what exists" (this file + the per-feature audit files) never blurs with "how we'd streamline it" (that file). Nothing in either file changes user-visible behavior by itself.
- **This file** — *how* to actually close the gaps: complete endpoints, auth, request sequence, response schema, concrete Flutter models/repository/service/controller changes, state management flow, real-time/WebSocket behavior, pagination, error handling, optimistic updates, loading states, retry behavior, media upload workflow. Still planning, not code — every entry stays a plan until the user explicitly asks to implement it.

### Per-feature template

```
## <Feature>

### Complete REST endpoints              — full list, method, confirmed vs. inferred
### Authentication requirements           — what's confirmed to work, what isn't tested
### Request sequence                      — order of calls for the feature's main flows
### Response schema                       — pointer to the audit file with full detail, key fields only here
### Models to create/change               — concrete Dart class changes
### Repository methods                    — concrete method signatures/responsibilities
### Service layer                         — concrete service class(es)
### State management flow                 — controller states, transitions
### Real-time update flow / WebSocket events — what's needed, what's optional/deferred
### Pagination strategy
### Error handling
### Optimistic updates
### Loading states
### Retry behavior
### Media upload workflow                 — if applicable
### Compatibility risks
### Parity approach                       — staged plan, cross-ref gap-analysis.md
```

---

## Messaging

### Reuse assessment
The existing layered architecture (`lib/messaging/` — models → services → repository → controllers → screens) **should be kept, not rewritten**. What changes is which backend API the service layer calls and what shape the models carry — the layering already matches this project's stated target pattern (`CLAUDE.md`) and doesn't need to change structurally.

### Target API decision — JWT compatibility now confirmed, still a staged migration, not a switch

**Confirmed (2026-07-07, curl, outside any browser):** Better Messages' REST API accepts JWT-bearer-only auth for both GET (`getFriends`) and POST (`checkNew`) — no cookie, no nonce. This was the core architectural risk; it's resolved. Confirmed for 2 of ~11 known endpoints; the rest are very likely the same (shared permission-check pattern within one plugin) but not each individually tested — a low-priority residual, not a blocker.

**Not resolved by this test, and a separate decision:** the WebSocket layer (`wss://cloud.better-messages.com`) — real-time push (unread counts, read receipts, presence) needs it, and it carries its own unresolved risks (third-party vendor dependency, untraced `sk`/`pdh` provisioning, no confirmed ToS position on mobile-client use). REST migration and WebSocket adoption are independent decisions — don't let "JWT works" imply "real-time works."

| | BuddyBoss REST (current) | Better Messages REST |
|---|---|---|
| JWT compatibility | Confirmed (app already uses it) | **Confirmed** (GET + POST tested directly) |
| Feature depth | Basic send/receive/mark-read only | Reactions, translations, per-message favorites, pin/mute/erase, audio/video calling, rich permissions, friend/block state |
| Matches website behavior | No — website doesn't use this API at all | Yes — this is what the website runs on |
| Real-time | 4s polling only | Live WebSocket available, but adoption is a separate, gated decision (see below) |
| Vendor risk | BuddyBoss Platform, same-origin | Third-party plugin + third-party cloud service for WS specifically |

### Complete REST endpoints (all confirmed, `/wp-json/better-messages/v1/`, JWT-bearer confirmed on the 2 tested)

| Endpoint | Method | JWT tested? | Purpose |
|---|---|---|---|
| `checkNew` | POST | ✅ confirmed | Incremental "what's new" poll |
| `threads` | POST | inferred only | Inbox list (`{"exclude": [...]}` pattern, not classic pagination) |
| `thread/{id}` | POST | inferred only | Full single-thread fetch |
| `thread/{id}/send` | POST | inferred only | Send message (optimistic `temp_id`/`temp_time` client pattern) |
| `thread/{id}/upload` | POST | inferred only | File upload — request/response shape not captured in detail |
| `thread/{id}/attachments` | — | inferred only | Confirmed to exist, not exercised |
| `thread/{id}/makePinned` / `/unmakePinned` | POST | inferred only | Returns bare `true` |
| `thread/{id}/erase` | POST | inferred only | Returns bare `true` |
| `callCreate` | POST | inferred only | `{thread_id, type:"audio"}` confirmed; `"video"` untested |
| `callMissed` | POST | inferred only | `{thread_id, type, message_id, duration}` |
| `getFriends` | GET | ✅ confirmed | Friend list w/ presence, call/block permissions |
| `getGroups` | GET | inferred only | Group threads tied to real BuddyBoss Groups |

### Authentication requirements
`Authorization: Bearer <JWT>` header only, confirmed sufficient — same token the app already obtains via `/jwt-auth/v1/token` and already attaches globally via `ApiService`. No new auth flow needed for the REST surface. (WebSocket auth is separate and unresolved — see Compatibility risks.)

### Request sequence (conversation-open flow, confirmed from the live WS+REST capture)
1. `thread/{id}` (POST) — full thread + messages + participant users.
2. (If pursuing real-time) WS `threadOpen` event — marks read, triggers `getUnread` push.
3. `checkNew` (POST) — incremental poll if not using WS.
4. Send: `thread/{id}/send` with client-generated `temp_id`/`temp_time`, reconciled against the real `message_id` in the next fetch/push.

### Response schema
Full schema in `messaging-better-messages.md` (thread/message/user objects, permission model). Key fields the models need: thread `isPinned`/`isMuted`/`isHidden`/`isDeleted`/`moderators`/`permissions`/`mentions`; message `reactions`/`translations*`/`favorited`/`temp_id`/`meta.files[]`.

### Models to create/change
- `MessageThread`: add `isPinned`, `isMuted`, `isHidden`, `isDeleted`, `moderators`, full `permissions` object, `mentions`.
- `ChatMessage`: add `reactions`, `translations`/`translationsSkipped`/`translationsPending`/`translationPending`, `favorited`, `temp_id`; replace speculative `bp_media_ids` attachment handling with the confirmed `meta.files[]` shape.
- New (if calling is pursued): a `Call`/`CallStatus` model — thread_id, type, duration, state.

### Repository methods
`MessagingRepository` would gain (additive, not replacing existing BuddyBoss-backed methods — see Parity approach): `getFriendsList()`, `getGroupThreads()`, `pinThread()`/`unpinThread()`, `eraseThread()`, `createCall()`/`reportMissedCall()`. Existing `refreshThreads()`/`getThread()`/`sendReply()`/`findOrCreateThreadWith()` would be reimplemented against Better Messages' endpoints if/when migrated, keeping the same method signatures so controllers/screens don't need to change.

### Service layer
New `BetterMessagesApiService` (mirrors the existing `MessagingApiService` — raw HTTP only, no business logic), one file, all endpoints above.

### State management flow
`ChatController`/`InboxController` keep their current `loading`/`error`/`sending` pattern — no structural change. New states needed only if calling is pursued (`callState`: idle/ringing/connected/ended) or if pin/mute become interactive (`pending` flag while a pin/mute request is in flight, matching the existing `sending` pattern already used for message send).

### Real-time update flow / WebSocket events
**Deferred, gated on a separate decision** (vendor ToS conversation, new `socket_io_client` pub.dev dependency, unresolved `sk`/`pdh` provisioning). If pursued: `subscribeToThreads`, `threadOpen`, `getUnread` (push), `threadInfoChanged` (push), `message_deleted`, `v2/threadEvent` (only `"thread_erased"` observed as a `type` so far) — full protocol in `messaging-better-messages.md`. Without it, `checkNew` polling (already working, already JWT-confirmed) is the fallback — same tradeoff the app already has today, just against a richer data source.

**Newly discovered, not yet investigated:** `better-messages/v1/app/*` (`login`, `savePushToken`, `getSettings`, `syncScripts`, found via the full REST route index — see `rest-route-index.md`) looks like a **purpose-built mobile-app integration path**, distinct from both the plain REST endpoints tested so far and the raw WebSocket. `savePushToken` specifically suggests real push-notification support (APNs/FCM token registration) rather than requiring the app to hold a persistent WebSocket connection at all — potentially a materially simpler and more mobile-appropriate real-time strategy than Stage C below. This needs direct investigation (what does `app/login` expect/return? is it a prerequisite for `savePushToken`? does it change how `checkNew`/threads behave?) before recommending WebSocket adoption over it. Treat as a fourth, higher-priority option to evaluate before Stage C, not an addition to it.

### Pagination strategy
`threads` uses an "exclude already-known IDs" pattern rather than page/offset — repository would need to track known thread IDs and pass them as `exclude`, similar in spirit to the existing cache-based approach in `MessagingRepository`.

### Error handling
Not yet characterized — no error-response shape captured for any Better Messages endpoint yet (all captured responses were successful). Needs a deliberate error-case capture (e.g. a bad thread ID, a permission-denied action) before this section can be filled in honestly.

### Optimistic updates
**Confirmed the website itself is optimistic on send** (`temp_id`/`temp_time` generated client-side, reconciled later) — directly informs the existing recommendation in `architecture-recommendations.md` to make `ChatController.send()` optimistic, now with a concrete reconciliation pattern to mirror (temp ID matching) rather than inventing one.

### Loading states
No change needed beyond what `ChatController`/`InboxController` already do (`loading`/`error`/empty), unless calling is pursued (needs its own transient UI state, e.g. an in-call overlay).

### Retry behavior
Not observed/characterized in any capture — no failed request was captured to see what retry (if any) the website's own JS performs.

### Media upload workflow
Confirmed storage path: `/wp-content/uploads/bp-better-messages/{yyyy}/{mm}/{dd}/{uuid}/{filename}` — a dedicated Better-Messages-only path, **not** BuddyBoss's `bp_media_ids` mechanism. This likely sidesteps the original handoff doc's caveat about `bp_media_ids` leaking attachments into public activity posts, since that risk is specific to BuddyBoss's own media component, not this path. `thread/{id}/upload`'s exact request shape (multipart fields, size limits) wasn't captured in detail — needed before implementing.

### Compatibility risks
0. **`better-messages/v1/app/*` (official mobile integration path) is unexplored** — should be investigated before committing to either the plain-REST approach or WebSocket for real-time, since it may supersede both. Highest-priority open item for this feature now.
1. Confirmed for only 2 of ~233 known endpoints (see `rest-route-index.md`) — low priority for the plain REST/JWT question specifically (the 2 tested are representative of GET/POST generally), but most of the surface (including all of `ai/*`) is entirely unexercised.
2. WebSocket layer: third-party vendor domain (`cloud.better-messages.com`), untraced `sk`/`pdh` provisioning, no confirmed ToS position for mobile-client use — needs a vendor conversation (echoes the original handoff doc's standing recommendation).
3. No confirmed API versioning contract for the REST/WS surface — plugin updates could change shapes without notice.
4. "Video" call type, "mute" action, and error-response shapes are all unconfirmed/unexercised — treat as unknowns, not assumed-working, until directly tested.
5. **"AI conversations"** were mentioned as a possible feature in this session but have no supporting evidence in any capture so far — not included in this blueprint pending clarification of where that came from.

### Parity approach — staged
1. **Stage A (done):** BuddyBoss REST for basic send/receive/mark-read.
2. **Stage B (now technically unblocked by the JWT confirmation):** adopt Better Messages REST for specific high-value, low-risk parity features — reactions, favorites, pin/erase, friends-list-based conversation starting — without touching real-time transport. Additive model/service changes, not a rewrite, since method signatures can stay stable per "Repository methods" above.
3. **Stage C (largest, still gated):** WebSocket real-time + calling — gated on the vendor conversation, a new pub.dev dependency decision, and (for calling) an entirely new UI surface that doesn't exist in the app today.

Nothing above is implemented — this is the plan to revisit when the user decides how far to pursue Stage B/C.
