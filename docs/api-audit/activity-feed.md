# Feature: Activity Feed / Timeline

## Status
- **Website:** Partial. Live-update mechanism confirmed (WP Heartbeat, see below). Full `buddyboss/v1/activity` route surface confirmed to exist (14 routes) via the public REST index — no response bodies captured yet, no dedicated Activity Feed HAR exists.
- **Flutter:** Confirmed in detail by reading the actual current code (`buddyboss_service.dart`, `post_model.dart`, `post_card.dart`, `timeline_page.dart`, `create_post_page.dart`, `home_page.dart`) — see Functional Behavior. **Contains a regression** (see below) contradicting `K54_PROJECT_HANDOFF.md`'s claim that the like-toggle full-reload bug was fixed.
- **Figma:** Not yet reviewed.

## ⚠️ Correction to a prior document

`K54_PROJECT_HANDOFF.md` states the Timeline like-toggle bug was fixed by having `TimelinePage` hold `List<Post>? _posts` as real state with a targeted `_applyPostUpdate()`, so `_loadTimeline()` would "never" run as a side effect of liking a post. **Reading the current `lib/Profile/timeline_page.dart` directly shows this is not the case:**

```dart
// timeline_page.dart
late Future<List<Post>> _timelineFuture;   // a Future, not a List<Post>? _posts field
...
itemBuilder: (context, index) {
  return PostCard(
    post: posts[index],
    onLikeChanged: () {
      setState(() {
        _loadTimeline();   // reassigns _timelineFuture — full network refetch
      });
    },
  );
},
```
`_loadTimeline()` reassigns `_timelineFuture` to a brand-new `Future`, wrapped in `setState()` — this puts the `FutureBuilder` back into `ConnectionState.waiting` (loading spinner) and refetches the entire feed from the network, exactly the bug the handoff doc claims was fixed. There is no `_applyPostUpdate` method anywhere in the file. Either the fix was reverted at some point after the handoff doc was written, or it was never actually applied — either way, **the live code today has the original bug**, not the documented fix. Flagging this prominently since trusting the handoff doc without checking would have meant building on a false premise.

One related fix *is* genuinely present: `home_page.dart` uses a stable `final GlobalKey _timelineKey` (not `ValueKey(DateTime.now())`) — that half of the original fix is real and confirmed in the current code.

## Network Behavior

### Website — live-update mechanism (confirmed, `.claude/k54global.com.har`)
Activity feed freshness rides the same WP Heartbeat mechanism documented in `notifications.md`: `admin-ajax.php`, `action=heartbeat`, carrying `data[bp_activity_last_recorded]` (a timestamp) and `data[bp_heartbeat][scope/order_by]=date_recorded`. This is how the website's "X new posts" banner knows to appear — not a dedicated polling endpoint. Full request shape in `notifications.md`; no activity-specific response body captured yet (the one full heartbeat response we have, from HAR2, didn't happen to include new activity at that moment).

### Website — full REST route surface (confirmed via `GET /wp-json/`, no capture needed)
```
GET,POST                              /buddyboss/v1/activity
GET,POST,PUT,PATCH,DELETE             /buddyboss/v1/activity/{id}
POST,PUT,PATCH                        /buddyboss/v1/activity/{id}/close-comments
GET,POST                              /buddyboss/v1/activity/{id}/comment
GET,POST,PUT,PATCH,DELETE             /buddyboss/v1/activity/{id}/comment/{comment_id}
POST,PUT,PATCH                        /buddyboss/v1/activity/{id}/favorite
POST,PUT,PATCH                        /buddyboss/v1/activity/{id}/notification
POST,PUT,PATCH                        /buddyboss/v1/activity/{id}/pin
POST                                  /buddyboss/v1/activity/{id}/share
GET                                   /buddyboss/v1/activity/details
POST                                  /buddyboss/v1/activity/featured-image/upload
POST,PUT,PATCH,DELETE                 /buddyboss/v1/activity/featured-image/upload/{id}
GET                                   /buddyboss/v1/activity/link-preview
GET                                   /buddyboss/v1/activity/sharing-settings
```
Plus `buddyboss/v1/pusher` (`auth`, `user-auth`, `data`) — likely Activity Feed's actual real-time transport (separate from messaging's Better Messages socket, confirmed unrelated to that system). Not yet investigated.

### App — confirmed from current code (not a raw capture, but very high confidence — see note below)
```
GET  /buddyboss/v1/activity[?user_id={id}]      — BuddyBossService.getTimeline()
POST /buddyboss/v1/activity/{id}/favorite        — BuddyBossService.toggleFavorite()
POST /buddyboss/v1/activity                      — BuddyBossService.createPost()
     body: {content, type:"activity_update", component:"activity", privacy}
```
**Confidence note:** these three are the only activity endpoints the app calls. None of the other 11 confirmed website-side routes (comment, pin, share, close-comments, notification, featured-image, link-preview, sharing-settings, details) are called anywhere in the app.

### Response schema — inferred from working code, not an independent raw capture
`buddyboss_service.dart` already contains extensive debug `print()` statements dumping the raw response (pre-existing in the code, not added by this audit) — strong evidence the field names below were derived from a real observed response at some point, even though we don't have that raw capture ourselves. Labeled **Inferred (high confidence)**, not Confirmed, per this audit's methodology — the app demonstrably works against these field names (per the original bug report), which is strong but not independent evidence.

```
{
  id, user_id, name, profession,
  content: { rendered: "..." } | "...",     // same rendered-object convention as messaging's excerpt
  avatar_urls: { thumb, full },
  feature_media: "https://...",              // direct image URL, OR:
  activity_data: { bb_activity_post_feature_image: { image: "..." } },  // nested fallback path
  favorite_count, comment_count, share_count,
  favorited: bool,
  can_edit: bool, can_delete: bool, can_comment: bool,
  is_pinned: bool,
  privacy: "public" | ...,
  preview_data: ...,
  type, date
}
```
`can_edit`/`can_delete`/`can_comment` being present per-item directly confirms per-post permission flags come back from the server — this is the Permissions dimension, already available, just not exercised for anything beyond gating the edit/delete menu (see Functional Behavior).

## Models to create/change
`Post` model (`lib/models/post_model.dart`) already has a `fromBuddyBoss()` factory covering the above — no new model needed, but note:
- **A second factory, `Post.fromJson()`, is dead Firestore-oriented code** (imports `cloud_firestore`, parses a `Timestamp`) — matches `CLAUDE.md`'s "Decide on Firebase's fate" note; confirmed still present and confirmed still unused (only `fromBuddyBoss` is called).
- **`profileLink` is built from the raw numeric `user_id`** (`"https://k54global.com/members/${json["user_id"]}"`, `post_model.dart:140`) — this is the **second occurrence** of the same pattern already flagged as unverified in the Profile row (real profile URLs use a slug, confirmed via `notifications.md`). Recurring pattern across two different files now, not a one-off — worth prioritizing the verification.

## Functional Behavior

**Business rules / permissions (confirmed from code):** `can_edit`/`can_delete` gate whether the post's `PopupMenuButton` shows Edit/Delete vs. just Report — the server-provided flags are correctly respected in the UI. **But Edit and Delete are both TODO stubs** (`// TODO: Edit post`, `// TODO: Delete post`) — the permission check is real, the actions behind it are not implemented at all. "Report" shows a confirmation dialog and a fake "Post reported" snackbar with **no actual API call** — entirely decorative.

**Optimistic updates:** the like button does mutate `post.likes`/`post.isFavorited` locally before calling `onLikeChanged`, matching the pattern described in the handoff doc — but per the regression above, that optimistic update is immediately moot, since `onLikeChanged` triggers a full reload that overwrites it with a freshly-fetched (loading-spinner-gated) list anyway.

**Comments and Share are entirely non-functional in the UI**, not just unimplemented in a service layer: `post_card.dart`'s comment and share buttons are literally `onPressed: () {}` — no navigation, no dialog, nothing. The `comment_count`/`share_count` numbers do display correctly (server data flows through fine), but tapping them does nothing at all.

**Create Post has extensive decorative UI** (`create_post_page.dart`):
- An image can be picked (`image_picker`) and previews correctly in the composer — **but the selected image is never sent** to `createPost()`, which only submits `content`/`type`/`component`/`privacy`. The picked file is silently dropped on publish. This is a real, confirmed bug, not a documented limitation.
- "Create post with AI" button has no `onTap` handler at all — plausible future integration point for the newly-discovered `k54-ai/v1/chat`/`create-group` endpoints (see `feature-inventory.md`'s AI Assistant row), not connected to anything today.
- Video, Attachment, and Emoji icon buttons are all empty `onPressed: () { /* comment only */ }` stubs.
- "Schedule this post," "Upload at highest quality," and "Turn off commenting" are three `SwitchListTile`s that only mutate local widget state — none of their values are ever sent to the server.
- The privacy selector displays hardcoded text ("Anyone") with a dropdown arrow icon that isn't wired to anything — always publishes `privacy: "public"` regardless of what's shown.
- "Save Draft" is a decorative button (`// Save Draft later`).

**Home page:** the search bar is a plain `TextField` with no `onChanged`/navigation wired — fully decorative. The Marketplace icon button is explicitly `// Marketplace page coming later`.

**State machine:** `TimelinePage` uses a single `FutureBuilder` over `_timelineFuture` — states are exactly `waiting` (spinner) / `error` (raw error text, no retry button — see below) / empty (`"No posts available"` text) / data (list). No distinct offline state.

**Loading/empty/error states:** loading = `CircularProgressIndicator`; empty = a centered "No posts available" text, still wrapped in a `RefreshIndicator` so pull-to-refresh works even when empty; error = `Center(child: Text(snapshot.error.toString()))` — a raw exception string shown directly to the user, no retry button, no friendly message.

**Retry behavior:** none beyond manual pull-to-refresh — no automatic retry, no backoff, confirmed by reading the code (no retry logic exists anywhere in `TimelinePage` or `BuddyBossService`).

**Pagination / infinite scroll:** **not implemented at all** — confirmed by reading `getTimeline()`: it's a single `GET /buddyboss/v1/activity` call with no `page`/`per_page` parameter, and `ListView.separated` renders the full returned list with no scroll-triggered "load more." Whatever the server's default page size is, that's the hard ceiling on how many posts the app ever shows.

**Media handling:** feed images render via `CachedNetworkImage` (loading placeholder + silent failure — `errorWidget` returns an empty `SizedBox`, no broken-image icon or retry). No video rendering path exists despite the website having a confirmed `video` component in `buddyboss/v1` (6 routes, unexplored) and the composer having a "Video" icon button that does nothing.

## Role / Account-Status Variations
Not tested — single account only. `can_edit`/`can_delete` presumably differ by ownership/role but this hasn't been verified against a second account.

## Undocumented / Plugin-Specific Behavior
`buddyboss/v1/pusher` — confirmed to exist, not investigated. Most likely the real-time delivery mechanism for the "new posts available" banner, since messaging is now conclusively proven to use a separate system (Better Messages' own socket).

## Open Questions
- Full response schema for `GET /buddyboss/v1/activity` — currently inferred from working code, not independently captured. A HAR of the app itself hitting this endpoint (or a curl test with the JWT) would upgrade this from Inferred to Confirmed.
- What does `buddyboss/v1/pusher/auth` actually gate — Activity Feed real-time, something else, or both?
- Response shapes for comment/pin/share/featured-image/link-preview — none captured, all currently unimplemented in the app.
- Is the like-toggle full-reload regression a reverted fix or one that was never actually applied? Not answerable from the code alone — would need git history inspection if it matters which.

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Like-toggle full reload | `K54_PROJECT_HANDOFF.md`: "TimelinePage now holds `List<Post>? _posts`... `_loadTimeline()` is now only called for pull-to-refresh... never as a side effect of liking a post" | `timeline_page.dart` (read directly, 2026-07-07): `_timelineFuture` is a bare `Future`, no `_applyPostUpdate` exists, `onLikeChanged` calls `_loadTimeline()` inside `setState()` — the exact bug the doc says was fixed | **Documentation Drift** + **Confirmed Bug** (the underlying behavior itself is also a real, currently-occurring bug, not just an outdated doc) |
| 2 | Image attachment on publish | Implied by UI: picking an image and seeing it preview suggests it will be included in the post | `create_post_page.dart`: `publishPost()` only sends `content`/`type`/`component`/`privacy` — `selectedImage` is never referenced in the network call | **Confirmed Bug** |
| 3 | Composer controls (AI, video, attach, emoji, schedule, quality, comments-off, save draft, privacy selector) | UI presents these as functioning options | All 9 confirmed to have no backend effect (empty handlers or local-only state) by reading the code directly | **UI-only Placeholder** (×9, itemized in Parity Scorecard below) |
| 4 | Edit/Delete/Report menu items | `can_edit`/`can_delete` flags from the server correctly gate menu visibility, implying the actions work | `edit`/`delete` are `// TODO` stubs; `report` shows a fake confirmation + snackbar with no API call | **UI-only Placeholder** (×3) — the *gating logic* is real and correct, the *actions* are not |
| 5 | Comments/Share feature | `comment_count`/`share_count` display, and 11 real REST routes exist for these actions | `post_card.dart`: both buttons are literally `onPressed: () {}` | **Missing Feature** (not a bug — nothing was ever built here, unlike #1/#2) |

## Parity Scorecard

**Capability list this score is computed from** (15 distinct user-facing capabilities, derived from the confirmed `buddyboss/v1/activity` route surface + heartbeat/pusher):
view feed, create post, edit post, delete post, add comment, edit/delete comment, favorite/like, pin, share, close-comments toggle, per-post notification toggle, featured-image upload, link-preview, real-time update banner, pagination/infinite-scroll.

- **Website Coverage:** 100% (baseline — see README's Parity Scorecard definition)
- **Flutter Coverage:** **3 of 15 fully working** (view feed, create text-only post, favorite) = **20%**. (Create-post-with-image counts as broken, not working; edit/delete/report don't count despite existing UI.)
- **Parity:** 20%
- **Confirmed Bugs:** 2 (like-toggle full reload, image silently dropped on publish)
- **Missing Features:** 11 (edit post, delete post, comments, pin, share, close-comments, per-post notification toggle, real featured-image upload, link-preview, real-time via pusher, pagination)
- **Decorative UI:** 12 (AI button, video icon, attachment icon, emoji icon, schedule switch, quality switch, comments-off switch, save draft, privacy selector, edit menu item, delete menu item, report menu item)
- **API Coverage:** 3 of 14 confirmed `buddyboss/v1/activity` routes called by the app = **21%**
- **Evidence Confidence:** rough tally of this file's findings — ✅ 9 (feed load, favorite toggle, both confirmed bugs, all 12 decorative-UI items, route existence for the 11 unused routes) / 🟡 2 (full response schema, comment/pin/share behavior) / 🔴 3 (pusher's actual role, whether the regression was reverted or never fixed, response shapes for the unused routes) → **(9 + 1)/14 ≈ 71%**. This is a reasoned tally from the findings above, not a precise instrument — shown so it's auditable rather than asserted.

## Implementation Blueprint

### Reuse assessment
`BuddyBossService`/`Post`/`TimelinePage`/`PostCard` structure is reasonable and should largely be kept — the fix needed for the confirmed regression is small and targeted (restore real list-state + `_applyPostUpdate`, not a rewrite). Everything else (comments, pin, share, featured image, link preview) is additive, not a restructuring.

### Complete REST endpoints
See Network Behavior above — 3 used, 11 confirmed-to-exist-but-unused, plus `pusher/*` for real-time.

### Authentication requirements
Already working — same JWT bearer the rest of the app uses. No new auth investigation needed for the BuddyBoss endpoints specifically (unlike messaging/courses).

### Request sequence
Feed load: `GET /activity` → render. Like: `POST /activity/{id}/favorite` → (currently, incorrectly) full reload; should be a targeted local update instead. Create: `POST /activity` → pop back to feed → (currently) full reload via `home_page.dart`'s `setState(() {})`, itself another full-feed-refetch-on-return pattern worth reconsidering alongside the like-toggle fix.

### Models to create/change
See above — no new model, fix `profileLink`'s URL format (shared issue with Profile), remove dead `Post.fromJson()`/Firestore code once confirmed safe (per `CLAUDE.md`'s existing dead-code list).

### Repository layer
None exists today — `BuddyBossService` is called directly from widgets (`TimelinePage`, `PostCard`, `CreatePostPage`), not through a repository, unlike the messaging module's layered pattern. Introducing an `ActivityRepository` (matching `CLAUDE.md`'s stated target architecture) would be the natural place to fix the reload regression and add comment/pin/share/media support without scattering more direct service calls across widgets.

### State management flow
Replace the bare `Future<List<Post>>` with real list state + targeted item updates (restoring what the handoff doc described but the code doesn't actually do).

### Real-time update flow
`buddyboss/v1/pusher` investigation needed before recommending anything beyond the current pull-to-refresh-only model.

### Pagination strategy
None exists; would need a `page`/`per_page`-based (or cursor-based, unconfirmed which the API supports) infinite-scroll implementation — currently a hard gap, not a partial one.

### Error handling / Retry behavior / Loading states / Empty states
All currently minimal-but-functional (see Functional Behavior) — no crashes, just no polish (raw error text, no retry button). Low-risk, low-effort improvement candidates for Phase 2, not correctness bugs.

### Media upload workflow
Confirmed broken for images specifically (picked image silently dropped on publish) — this is a real bug fix candidate, not just a missing feature, since the UI implies it works.

### Compatibility risks
None specific to auth (BuddyBoss REST already confirmed working). Main risk is scope — comments/pin/share/media are a substantial amount of new UI + service work, not a quick pass.

### Parity approach
1. Fix the confirmed like-toggle regression and the image-drop bug first — both are correctness bugs, not parity gaps, and cheap relative to the rest.
2. Add comment thread UI + REST wiring (biggest single confirmed gap).
3. Add pin/share/featured-image/link-preview once comments are solid.
4. Investigate `pusher/*` before deciding on any real-time investment beyond pull-to-refresh.
5. Pagination is a hard prerequisite for the feed being usable at scale — should not be deprioritized indefinitely once account activity volume grows.
