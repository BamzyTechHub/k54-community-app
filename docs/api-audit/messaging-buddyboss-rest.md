# Feature: Messaging — BuddyBoss REST API (Flutter app's system)

This covers the JWT-authenticated `/wp-json/buddyboss/v1/messages*` surface the Flutter app uses. It is **not** what the website's own `/messenger/` UI calls — that's Better Messages, documented separately in `messaging-better-messages.md`. Do not merge findings between the two files.

## Status
- **Website:** N/A for this file — the website doesn't call this API for its own messaging UI (see system split in `README.md`). Whether any *other* part of the website calls it is unconfirmed.
- **Flutter:** Partial. Inbox load confirmed working end-to-end. Single-thread (`GET /messages/{id}`) response shape not yet exercised — the inbox crash blocked reaching it until this session; no capture of it exists yet.
- **Figma:** Not yet reviewed.

## Network Behavior

Confirmed from the app's own live traffic against `k54global.com`, captured via temporary debug logging in `MessagingRepository` (session date 2026-07-06):

| Endpoint | Method | Confirmed? | Notes |
|---|---|---|---|
| `/jwt-auth/v1/token` | POST | Confirmed | `{username, password}` → `{token, ...}`. Unrelated to messaging but gates everything else. |
| `/buddyboss/v1/messages?box=inbox&user_id={id}&per_page=50` | GET | Confirmed | Top-level response is a JSON **array** of thread objects (confirmed `response.data.runtimeType == List<dynamic>`). `per_page` is hardcoded to 50 in `MessagingApiService.getThreads()` — no pagination beyond page 1 is implemented client-side (see Edge Cases). |
| `/buddyboss/v1/messages/{thread_id}` | GET | Not yet captured | Code path exists (`MessagingRepository.getThread()`) but never successfully exercised yet — the inbox crash occurred while parsing the inbox list itself, before any thread was ever opened. |
| `/buddyboss/v1/messages` | POST (reply) | Not yet captured | `{id: threadId, message}` |
| `/buddyboss/v1/messages` | POST (new thread) | Not yet captured | `{message, recipients: [id]}` |
| `/buddyboss/v1/messages/action/{thread_id}` | POST | Not yet captured | `{action: "unread", value: false}` — used for mark-read only; mark-unread/hide/delete actions are supported by the same endpoint per `MessagingApiService.markThread()`'s signature but never called with those values anywhere in the app. |
| `/buddyboss/v1/members?search={q}&per_page=20` | GET | Not yet captured (informally exercised via New Conversation search, not logged) | |

### Confirmed response shape details (thread object, from inbox list)
- `recipients`: a **JSON object keyed by user ID** (e.g. `{"5": {id: 8, user_id: 5, ...}}`), not an array. `id` on each recipient is the `bp_messages_recipients` row's own ID; `user_id` is the actual WP user ID — these are different numbers and must not be conflated (this was the root cause of two bugs fixed this session).
- `excerpt` (and by extension, likely `subject`/`message` — unconfirmed for the latter two): a WP REST-style `{rendered: "...", raw: "..."}` object, not a plain string.
- `unread_count`: handled defensively as either bool or int in `MessageThread.fromJson` — this predates the current investigation and hasn't been re-verified against live data; the live payload's actual type for this field is still unconfirmed.

### Not yet confirmed
- `messages` field shape on a single-thread response (List vs. Map — same ambiguity `recipients` had, unverified).
- Error response shapes (invalid thread ID, unauthorized access to someone else's thread, etc.).
- Rate limiting — none observed, none documented by BuddyBoss publicly for this endpoint.
- Whether `/buddyboss/v1/messages` POST for a new thread returns the full thread object or something leaner.

## Functional Behavior

**Business rules (from `MessagingRepository`, confirmed by reading the code):**
- One thread per (current user, other user) pair is enforced client-side only, via `findOrCreateThreadWith()` scanning the in-memory thread cache before calling `startThread`. There is no evidence yet of server-side dedup — if the cache is cold (e.g. fresh app install, or two devices), duplicate threads could plausibly be created. Unconfirmed against the live API.
- Polling runs on a fixed 4-second interval (`ChatController._pollInterval`), not adaptive/backoff.
- A thread is marked read only when its `ChatPage` is opened (`ChatController.load()` calls `markThreadRead` unconditionally on every open, not just the first time or only if there were unread messages).

**Validation rules:**
- `ChatController.send()`: rejects empty/whitespace-only text (`text.trim().isEmpty`) and rejects a second send while one is already in flight (`sending` flag) — both client-side only, no evidence of server-side equivalents yet.
- No message length limit enforced client-side.
- `InboxController`'s search filter matches on `otherUserName` or `lastMessagePreview` substring, case-insensitive, client-side only against already-loaded threads (not a server search).

**Feature flags / conditional behavior:** none found. No role, permission, or account-status branching exists anywhere in the messaging module's client code.

**UI interactions & transitions:**
- Inbox: pull-to-refresh, floating "new message" button, unread threads rendered bold (via `MessageThread.isUnread`), relative timestamps ("Yesterday", "3d ago", else `d/m/y`).
- Chat: `Timer.periodic` polling appends new messages without re-rendering the full list; sending clears the input immediately but the bubble only appears once the server responds (non-optimistic — differs from the Timeline like-button's optimistic pattern elsewhere in the app).

**State machine (derived directly from controller fields, not yet compared to website):**
- `InboxController`: `loading` (bool) / `error` (String?) / implicit success (neither set, `_threads` populated). No distinct "empty" state constant — `messages_page.dart` renders an empty-state message directly when `threads.isEmpty`, no offline-specific state (a network failure just becomes a generic `error` string).
- `ChatController`: `loading` / `sending` / `error`, same shape. Same absence of a distinct offline state — network errors surface as the caught exception's `toString()`.

**Client-side logic not obvious from the API:**
- `pollNewMessages()` re-fetches the *entire* thread every 4 seconds and diffs client-side against the last known message ID — there is no server-side "since" filter to use instead (per code comments; unconfirmed whether BuddyBoss actually lacks one or it's just unused).
- `unreadCount` (global `ValueNotifier`, drives both nav badges) is recalculated client-side from the cached thread list on every mutation — not fetched from any dedicated "unread count" endpoint.
- `MessagingRepository` is a singleton in-memory cache; a cold start always re-fetches from the network — no persistence across app restarts.

**Server-side assumptions inferred from responses:** BuddyPress core's internal `BP_Messages_Thread::$recipients` structure (associative by user ID) appears to be exposed as-is through the REST layer rather than being normalized into a list — i.e. the REST API looks like a fairly direct serialization of internal BuddyPress objects rather than a purpose-built API contract. Inferred, not confirmed by any BuddyBoss documentation.

**Edge cases / unusual behavior observed:**
- **New finding, not yet reproduced live:** `InboxController.load()` (in `inbox_controller.dart`) has the identical unguarded-`notifyListeners()`-after-dispose structure that `ChatController.load()` had before this session's fix — it awaits `_repo.refreshThreads()` then calls `notifyListeners()` unconditionally in its `finally` block, with no `_disposed` guard, and `_MessagesPageState.dispose()` doesn't cancel anything in flight. The same "used after disposed" crash class is plausible here (e.g. leaving the Messages tab quickly after opening it, or after returning from New Conversation while a re-load is in flight). Found by code inspection while documenting this feature, not yet reproduced on-device. **Not fixed** — implementation is out of scope until the audit is complete, per current instructions. Flagging so it isn't lost.
- No pagination beyond the first 50 threads (`per_page: 50` hardcoded) — an account with more than 50 conversations would silently never see the rest.
- Group threads (>2 participants) are explicitly unhandled in `MessageThread.fromJson` (picks one "other" participant only) — behavior for an actual group thread from the live API is completely unknown.

## Role / Account-Status Variations

Not tested — only one account/role has been used against the live site so far in this project. The Flutter code itself implements **zero** role-based differentiation anywhere in the messaging module (no admin-only actions, no blocked-account handling, no differing permissions), which is itself worth treating as a likely gap once website behavior for other roles is confirmed (e.g. can an admin delete any thread? can a blocked/pending member message anyone?).

## Undocumented / Plugin-Specific Behavior

None traced yet — pending a captured single-thread response and error-case responses.

## Open Questions

- What shape is `messages` on a single-thread response — List or Map like `recipients` was?
- Does `/buddyboss/v1/messages` POST for a new thread genuinely prevent server-side duplicate threads, or is dedup purely the app's own cache-check (meaning a cold cache could create dupes)?
- What does an error response actually look like (wrong thread ID, no permission, rate-limited)?
- Is there truly no "since"/incremental filter on the messages endpoint, or has that just never been tried?
- Confirm `unread_count`'s real type against a live payload (bool vs int — currently only defensively handled, not verified).
