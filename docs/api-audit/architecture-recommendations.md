# Architecture & Reuse Recommendations (Phase 2 backlog)

Opportunities noticed while documenting the platform in Phase 1 — reusable API/service patterns, or improvements to the current Flutter architecture — that would still preserve full compatibility with the website. **Nothing here is implemented during Phase 1.** This list feeds Phase 2 planning; it is not a parity gap (the app isn't "wrong" for not having these yet), so it stays out of `gap-analysis.md`.

Each entry: what was noticed, why it matters, what it would touch if acted on later.

### Make chat send optimistic (confirmed match to website behavior)
**Noticed:** `ChatController.send()` currently waits for the server response before showing a sent message. The website's own Better Messages frontend does the opposite — generates a `temp_id`/`temp_time` client-side immediately, shows the message right away, then reconciles against the real `message_id` once the server responds (confirmed directly from captured traffic, see `messaging-better-messages.md`).
**Why it matters:** this was already flagged as a nice-to-have in the original handoff doc; now it's confirmed as literally how the functional-parity target (the website) behaves, which strengthens the case.
**What it would touch:** `ChatController.send()`, `ChatMessage` (would need a client-generated temp ID + pending/sent state), `chat_page.dart`'s bubble rendering.

### Consider whether messaging should target Better Messages' REST API instead of BuddyBoss's
**Noticed:** Better Messages exposes a complete, separate REST API (`/wp-json/better-messages/v1/*`) with reactions, translations, per-message favorites, pin/mute/erase, audio/video calling, and a much richer permission/friend/block model than BuddyBoss's own `/buddyboss/v1/messages` — see the full inventory in `messaging-better-messages.md`.
**Why it matters:** true feature parity with the website's messaging experience (calls, reactions, translation, moderation) is likely only reachable via this API, not BuddyBoss's simpler one.
**What it would touch:** the entire `lib/messaging/` module. **Update 2026-07-07: the auth risk is resolved** — JWT-bearer-only auth confirmed working for both GET and POST via direct curl testing, no cookie/nonce needed. This is now a live, staged recommendation rather than a blocked question — see the full plan in `implementation-blueprint.md`.

### Consolidate friend/member data sources once Better Messages REST is adopted
**Noticed:** `getFriends`/`getGroups` (Better Messages) return the same kind of `users[]`-shaped data (id, name, avatar, presence, friend/block/call-permission flags) that `MessagingRepository.searchMembers()` currently gets from a completely different source (`/buddyboss/v1/members?search=`). If Stage B of the messaging migration (see `implementation-blueprint.md`) goes ahead, `NewConversationPage`'s member picker could consolidate onto `getFriends`/`getGroups` instead of maintaining a separate BuddyBoss members-search call for what is functionally the same "who can I talk to" concern.
**Why it matters:** one data source instead of two for overlapping data reduces the surface area to keep in sync, and matches the website's own apparent behavior (its picker seems to use `getFriends`, not a generic member search — see the still-open friends-only question below).
**What it would touch:** `MessagingRepository.searchMembers()`, `NewConversationPage`. Not a parity gap by itself — purely a "reduce duplication" opportunity, contingent on the Stage B decision.

### Wire Members Directory's Message button to the already-working messaging flow
**Noticed:** `members_page.dart`'s per-card Message button is an empty `onPressed` stub, but `MessagingRepository.findOrCreateThreadWith()` — the exact function needed here — already works and is used successfully from `ProfileActions` and `NewConversationPage`. This isn't a "build new capability" gap, it's a "connect an existing working thing" gap.
**Why it matters:** cheapest possible fix once Members Directory has real data — no new backend work, no new Flutter service, just wiring.
**What it would touch:** `members_page.dart`'s Message `IconButton`.

### Reuse `UnreadBadge` on the Notifications entry icon
**Noticed:** `home_page.dart` wraps the Messages icon in `UnreadBadge` (a real, working component from the messaging module) but not the Notifications icon, which has no badge at all.
**Why it matters:** the component already exists and works — this is a "reuse an existing widget" task, not new development, once notifications have a real unread-count source.
**What it would touch:** `home_page.dart`'s notification `IconButton`.

### Consider a shared user/presence cache across features
**Noticed:** Better Messages embeds full user objects (`id`, `name`, `avatar`, `url`, presence, friend/block state) directly in its thread/friends/groups responses, avoiding N+1 lookups. As Members, Friends, and Groups get audited and implemented, several features will likely want the same user/presence data (e.g. presence indicators aren't just a messaging concept — the Heartbeat-delivered `users_presence` in `notifications.md` is platform-wide, not messaging-specific).
**Why it matters:** if each feature area builds its own independent user cache, presence/friend-state can drift out of sync between screens (e.g. a user shown online in Messaging but not in a Members list). A single shared cache (perhaps a `UserRepository` other repositories compose) would avoid that class of bug before it's ever written.
**What it would touch:** speculative until Members/Friends are actually audited — recorded now so it isn't forgotten, not sized yet.

### Investigate the friends-only new-conversation restriction
**Noticed:** `getFriends` (used seemingly for the website's conversation-starting picker) returned only `isFriend: 1` entries, suggesting the website may restrict starting new conversations to friends, unlike the app's `NewConversationPage`, which searches all members.
**Why it matters:** if real, this is actually a parity *gap* (app is more permissive than the website), not just an architecture nicety — worth moving to `gap-analysis.md` once confirmed rather than leaving it here indefinitely.
**What it would touch:** `NewConversationPage`, `MessagingRepository.searchMembers()`.
