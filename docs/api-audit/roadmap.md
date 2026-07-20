# K54 App — Build Roadmap

Living planning doc, updated as findings change. Cross-references the deeper per-feature audit files (`courses.md`, `activity-feed.md`, `messaging-better-messages.md`, `rest-route-index.md`) rather than repeating their full detail - this file exists to answer "what do we build next, and in what order."

## How to read this

- **✅ Ready to build** — real endpoint confirmed, request/response shape known, no blockers.
- **🟡 One step away** — real endpoint confirmed to exist, but needs one more concrete thing (a live capture, a permission check, a test) before building against it safely.
- **🔴 Blocked** — not fixable from the Flutter app alone (needs a WordPress-side config/capability change, or doesn't exist on the backend at all).

---

## ✅ Ready to build now

| Feature | What to build against |
|---|---|
| Course catalog (real data) | `GET /wp/v2/courses` + `GET /wp/v2/media/{id}` for images. Confirmed live 2026-07-19 with the real "K54 Global Growth Program" course. Replaces the dummy `courses` list in `courses_page.dart`. |
| Photo attachments on posts | `bp_media_ids` field on `/buddyboss/v1/activity` - real image URLs at `attachment_data.full`/`activity_thumb`. Not currently parsed by `Post.fromBuddyBoss` at all - separate mechanism from the featured-image field already used. |
| Document attachments on posts | `bp_documents` field, same endpoint - real `filename`/`extension`/`size`/`download_url`. Same "not parsed yet" gap as photos. |
| **Inline video playback on posts** | `bp_videos` field's `url` (the `bb-video-preview/...` link) - confirmed 2026-07-20 to be a **direct, streamable `video/mp4` response** (tested live: `Content-Type: video/mp4`, real bytes returned). A native `video_player`/`VideoPlayerController.networkUrl` can play this directly, passing the JWT as an `Authorization` header. No WebView needed. |
| Voice notes (send) | `POST /better-messages/v1/thread/{id}/sendVoice` (+ `/thread/new/sendVoice` for a first message). Route confirmed to exist; request/response body not yet captured - build defensively, same discipline as every other unconfirmed-body Better Messages call already in the codebase. |
| Forward message | `POST /better-messages/v1/message/{message_id}/forward`. Same caveat - route confirmed, body shape not captured. |
| Pin/unpin/delete/clear message | Confirmed routes under `thread/{id}/pinMessage` \| `unpinMessage` \| `clearMessages` \| `deleteMessages`. |
| Group join/invite/requests | `/buddyboss/v1/groups/{id}/members`, `/groups/membership-requests`, `/groups/invites`. |
| Clickable links in posts | Done this session (`onLinkTap` wired in `post_card.dart`). |
| Long-press select/copy on posts | Done this session (`SelectionArea` wrapping the card). |
| Post "..." menu visual style | Done this session (custom overlay, matches app's own cream/green look instead of Flutter's default purple). |

## 🟡 One step away

| Feature | What's needed |
|---|---|
| Course lesson/topic/quiz detail | `tutor/v1/topics`/`tutor/v1/lessons` return `403` even for a real logged-in member (same wall `tutor/v1/courses` had, but no `wp/v2` post-type workaround exists for these - checked, none registered). **Next step:** check whether this test account is actually *enrolled* in "K54 Global Growth Program" - if enrollment lifts the gate, that's a real, buildable "enroll → fetch curriculum" flow. If not, this needs a WordPress-side capability grant for regular members, not an app fix. |
| Message edit | The UI option is confirmed real (screenshot of the live site's message menu: Copy/Reply/Forward/**Edit**/Pin/Favorite/Delete), but no REST route was found for it, and directly probing `/better-messages/v1/message/{id}` confirms it isn't a real registered endpoint (`OPTIONS` returns `200 []`). **Next step:** either a live HAR/DevTools capture of someone actually tapping "Edit" on the real site, or a deliberate test with a disposable throwaway message (not a real conversation) sent specifically to probe candidate request shapes. Didn't want to guess against real message history. |
| Message reactions (in chat) | `POST /better-messages/v1/reactions/save` confirmed to exist (used already for something else in this codebase? - double check), never wired into the chat screen's UI. Needs the request/response shape confirmed with a live capture. |
| Message translation | `better-messages/v1/ai/*` namespace confirmed real (8 routes covering translation among other things). Not wired in; needs a capture. |
| Read receipts / typing indicators | Confirmed real (WebSocket events `getStatuses`, `subscribeToThreads`, presence pushes) but living on Better Messages' proprietary `wss://cloud.better-messages.com` layer, not plain REST. Adopting this is a bigger architectural decision (third-party WebSocket dependency) - see `implementation-blueprint.md`'s Messaging section for the full tradeoff writeup already done. |

## 🔴 Blocked (not an app fix)

| Feature | Reality |
|---|---|
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

## Suggested build order

1. **Course catalog** (fully unblocked, highest visible payoff - replaces dummy data entirely)
2. **Post attachments: photos + documents** (data already flows through the same endpoint the feed already calls, just needs parsing + rendering)
3. **Inline video playback** (endpoint confirmed working, needs a `video_player` package addition + a bit of UI)
4. **Voice notes + Forward message** (both real endpoints, need one capture pass each to confirm request/response shape before wiring)
5. **Course enrollment check** (determines whether lesson/topic detail is reachable at all without a WordPress-side change)
6. **Message edit** (needs the disposable-test-message approach or a real capture - flagged as lowest priority of the "one step away" items since it's the most manual to resolve)
