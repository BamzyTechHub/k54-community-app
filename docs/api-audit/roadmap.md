# K54 App — Build Roadmap

Living planning doc, updated as findings change. Cross-references the deeper per-feature audit files (`courses.md`, `activity-feed.md`, `messaging-better-messages.md`, `groups.md`, `rest-route-index.md`) rather than repeating their full detail - this file exists to answer "what do we build next, and in what order."

## 2026-07-20 update — everything in last week's "Ready to build now" is now built

Course catalog, photo/video/document post attachments, voice notes, forward, pin/delete/clear message actions, and group join/request-to-join are all wired and shipped this pass (see the per-item notes below, kept for the exact confirmed request/response shapes). What moved:
- **Voice notes & forward** had their exact request/response shapes confirmed via a disposable-message live test against thread 72 (sent, verified, then deleted - see `messaging-better-messages.md`'s Open Questions section for the full shapes). Both are now real two-step (upload → reference by id) / one-call flows, not guesses.
- **Groups** turned out to already expose far richer per-user state (`is_member`, `can_join`, `role`, `request_id`) than the app was using - the "membership request" gap wasn't really about a missing endpoint, it was about the app never reading fields the API was already sending. Now wired; see `groups.md`'s 2026-07-20 update.
- **Group invites** (inviting a specific person into a specific group) is confirmed real (`POST groups/invites`) but genuinely not buildable yet - it needs a group-detail screen with a member picker, which doesn't exist. Added as a new "Ready to build" item below since the endpoint itself is no longer a blocker, only the missing screen is.

## How to read this

- **✅ Ready to build** — real endpoint confirmed, request/response shape known, no blockers.
- **🟡 One step away** — real endpoint confirmed to exist, but needs one more concrete thing (a live capture, a permission check, a test) before building against it safely.
- **🔴 Blocked** — not fixable from the Flutter app alone (needs a WordPress-side config/capability change, or doesn't exist on the backend at all).

---

## ✅ Shipped this pass (2026-07-20)

| Feature | Built against |
|---|---|
| Course catalog (real data) | `GET /wp/v2/courses` (+ `_embed=1` for featured image/author). `courses_page.dart` fully rewired, dummy rating/lesson-count rows removed since no such fields exist. |
| Photo/document/video attachments on posts | `bp_media_ids`/`bp_documents`/`bp_videos` on `/buddyboss/v1/activity`, parsed in `post_model.dart` and rendered in `post_card.dart` (grid + full-screen viewer for photos, lazy-init inline player for video, download tile for documents). |
| Voice notes (send + play) | Two-step flow confirmed live via disposable-message test: `POST thread/{id}/upload` (multipart field `file`) → `{id}`, then `POST thread/{id}/sendVoice` `{attachment_id}`. Recording via the `record` package, playback via `audioplayers`, wired end-to-end in `chat_page.dart`. |
| Forward message | `POST message/{id}/forward` body `{"thread_ids": [...]}`, confirmed live. Thread-picker bottom sheet in `chat_page.dart`. |
| Pin/unpin/delete message | `POST thread/{id}/pinMessage`/`unpinMessage` body `{"messageId": int}` (camelCase - confirmed the only shape that works), `POST thread/{id}/deleteMessages` body `{"messageIds": [...]}`. Long-press message menu in `chat_page.dart`. |
| Group join / private-group request-to-join | `POST groups/{id}/members` (public, `can_join: true`) vs. `POST groups/membership-requests` (private) - the list endpoint's own `is_member`/`can_join`/`role`/`request_id` fields (previously unused) drive the button state directly, including a real "Requested" (cancelable) state for private groups. |
| Clickable links, long-press select/copy, post "..." menu styling | Done earlier this week. |
| Photo/video attach on Create Post (write side) | `POST media|video/upload` (multipart) then `POST media|video` with `{upload_ids, activity_id}` - confirmed live 2026-07-20 via a disposable test post. The old "Photo not supported yet, publish without it?" dialog is gone; photos and videos actually attach now. |
| Generic image attach in chat (not voice) | `thread/{id}/upload` (same as voice) then `send` with `{"message": "<!-- BM-ONLY-FILES -->", "files": [id]}` - confirmed live 2026-07-20 (three other plausible field names silently attached nothing). Chat's attach/camera icons now send real images via image_picker. |

## ✅ Ready to build now

| Feature | What to build against |
|---|---|
| Group invites (invite a specific person to a specific group) | `POST groups/invites` body `{user_id, inviter_id, group_id, message, send_invite}`, confirmed real from the route index's arg schema. Not built yet - needs a group-detail screen with a member picker, which doesn't exist in the app yet (only the list/directory page does). This is the actual remaining piece, not the endpoint. |
| Message reactions (in chat) | `POST /better-messages/v1/reactions/save` confirmed to exist, never wired into the chat screen's UI (the activity-feed reaction picker already uses a *different*, confirmed `buddyboss/v1/reactions` endpoint - don't conflate the two). Needs the request/response shape confirmed with a live capture or disposable-message test, same approach used for voice/forward/pin/delete above. |
| Message translation | `better-messages/v1/ai/*` namespace confirmed real (8 routes covering translation among other things). Not wired in; needs a capture. |

## 🟡 One step away

| Feature | What's needed |
|---|---|
| Message edit | The UI option is confirmed real (screenshot of the live site's message menu: Copy/Reply/Forward/**Edit**/Pin/Favorite/Delete), but no REST route was found for it, and directly probing `/better-messages/v1/message/{id}` confirms it isn't a real registered endpoint (`OPTIONS` returns `200 []`). Unlike voice/forward/pin/delete (which turned out to be guessable once the right camelCase/snake_case shape was found), edit has no candidate route at all in the full 233-route `better-messages/v1` index - it's not a shape-guessing problem. **Next step:** a live HAR/DevTools capture of someone actually tapping "Edit" on the real site is the only way forward here. |
| Read receipts / typing indicators | Confirmed real (WebSocket events `getStatuses`, `subscribeToThreads`, presence pushes) but living on Better Messages' proprietary `wss://cloud.better-messages.com` layer, not plain REST. Adopting this is a bigger architectural decision (third-party WebSocket dependency) - see `implementation-blueprint.md`'s Messaging section for the full tradeoff writeup already done. |

## 🔴 Blocked (not an app fix)

| Feature | Reality |
|---|---|
| Course lesson/topic/quiz detail | **Resolved as blocked, 2026-07-20** - tested every `tutor/v1` sub-resource (`courses/{id}`, `course-contents/{id}`, `topics`, `author-information/{id}`) against the real course; all return the identical `403 rest_forbidden`, which is the signature of a namespace-wide capability check, not an enrollment check. No `wp/v2` post-type workaround exists (no `lesson`/`topic`/`quiz` post type is registered for Tutor). Needs a WordPress-side capability/permission change - not buildable from the app alone. See `courses.md`'s Open Questions for the full reasoning. |
| Live streaming | WPStream plugin is installed, but its public REST surface is just one endpoint (`playback-session-verify`). Real integration would go through WPStream's own SDK/embed, which hasn't been investigated - this is a "does WPStream have a documented mobile SDK" research question, not an endpoint-finding one. |
| Voice/video calling | Permissions (`canVideoCall`/`canAudioCall`) are real, but the actual call mechanism runs over the same proprietary WebSocket layer as read receipts/typing. Same bigger-decision bucket. |
| Self-service account deactivation/deletion | Only an admin-capable WordPress route exists (`better-messages/v1/admin/deleteAccount`). No user-facing path. |
| Two-factor authentication | No 2FA plugin/system detected anywhere in the full 842-route index. |
| Push notifications | App currently polls. Better Messages has an `app/*` namespace (`savePushToken`, `getSettings`) that looks like a real official mobile-integration path - flagged as a lead in `messaging-better-messages.md`, not yet investigated. |

---

## On "getting every endpoint" going forward

The full 842-route index across all 37 plugin namespaces is already captured and documented in `rest-route-index.md` - re-fetching `GET https://k54global.com/wp-json/` gets the same list fresh anytime, no login or setup needed (confirmed safe, read-only, zero-cost). What that index *doesn't* tell you automatically is:
1. **Whether a route needs auth, and what permission level** - found by direct `OPTIONS`/test calls per route, which is what's been happening this whole audit. Not worth pre-computing for all 842 at once; better to check the ones relevant to whatever's being built next.
2. **What a real request/response body looks like** - only discoverable by either (a) a live authenticated test call (what's been done for Courses, activity attachments, and the video URL), or (b) watching the real website's own network traffic while a human performs the action (needed for message-edit specifically, and generally anywhere a write action's exact field names matter and guessing risks a silent wrong request).

### On "temporary login" / triggering things directly

No new temporary login is needed - the credentials already provided work fine for direct, repeatable API testing (this is exactly how the Courses/attachment/video findings above were confirmed). What that access **can't** do is stand in for a real browser: there's no way to capture the exact network request a piece of client-side JavaScript fires when a button is clicked, short of either watching it happen (DevTools Network tab, or a HAR export) or deliberately testing a guessed request shape against **disposable test data** (never against real conversation/post history, to avoid silently corrupting something real). Message-edit is the one open item that specifically needs this - everything else this pass was resolved by direct API calls alone.

## Suggested build order (remaining)

1. **Course enrollment check** (determines whether lesson/topic detail is reachable at all without a WordPress-side change)
2. **Group-detail screen + invite flow** (unlocks the confirmed-real `groups/invites` endpoint, plus is generally useful groundwork - member list, group feed, etc.)
3. **Message reactions in chat** (one disposable-message test away, same playbook as voice/forward/pin/delete)
4. **Message translation** (needs a capture of the `ai/*` namespace in use)
5. **Message edit** (needs a real HAR/DevTools capture - no route exists to guess against)
