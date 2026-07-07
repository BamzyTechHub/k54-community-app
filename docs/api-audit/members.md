# Feature: Members Directory

## Status
- **Website:** Partial. Live-filtering mechanism confirmed via legacy `admin-ajax.php` (`action=members_filter`), request shape only — no response body captured. Full `buddyboss/v1/members` REST surface confirmed (12 routes) via the public route index.
- **Flutter:** Confirmed via direct code reading — `lib/screen/members_page.dart` is 100% hardcoded dummy data with zero API wiring and zero navigation (tapping a member card does nothing at all — confirmed by grep, no `onTap`/`GestureDetector`/`Navigator` call exists on the member card widgets, only on the tab switcher).
- **Figma:** Not yet reviewed.

## Network Behavior

### Website — legacy AJAX (✅ Confirmed request shape, 🔴 Hypothesis for response — `.claude/k54global.com.har`, 2026-07-07)
```
POST /wp-admin/admin-ajax.php
action=members_filter
scope=following, filter=active, search_terms=, page=1, order_by=, method=reset
object=members, target=#buddypress [data-bp-list], template=, ajaxload=true
```
✅ Confirmed: `scope` (at least `following` observed — implies other scope values like `all`/`personal` likely exist, unconfirmed which), `filter=active`, `page`-based pagination, `order_by` (empty in this capture — default sort unconfirmed), `search_terms`. No response body captured (Source: HAR1 exported without content). 🔴 Hypothesis: full set of valid `scope`/`filter`/`order_by` values, response schema.

### Website — full REST surface (✅ Confirmed to exist via `GET /wp-json/`, 🔴 Hypothesis for all response bodies — none exercised)
```
GET,POST                    /buddyboss/v1/members
GET,POST,PUT,PATCH,DELETE   /buddyboss/v1/members/{id}
GET                         /buddyboss/v1/members/{id}/detail
GET                         /buddyboss/v1/members/{id}/info
GET,POST,DELETE             /buddyboss/v1/members/{user_id}/avatar
GET,POST,DELETE             /buddyboss/v1/members/{user_id}/cover
POST,PUT,PATCH              /buddyboss/v1/members/action/{id}
GET                         /buddyboss/v1/members/details
GET,POST,PUT,PATCH,DELETE   /buddyboss/v1/members/me
GET                         /buddyboss/v1/members/me/permissions
POST                        /buddyboss/v1/members/presence
GET                         /buddyboss/v1/members/profile-dropdown
```
Notable, not previously cross-referenced: `{user_id}/avatar` and `{user_id}/cover` exist at the **members** level (not just xprofile) — directly relevant to the Profile/XProfile audit next, since avatar/cover upload was an open item there. `members/action/{id}` is a generic action endpoint (pattern matches `activity/action` — likely follow/unfollow/block, unconfirmed which actions). `members/me/permissions` and `members/presence` are both new, unexplored leads.

### App — ✅ Confirmed (the only real member-related call in the app)
```
GET /buddyboss/v1/members?search={query}&per_page=20
```
Source: `lib/messaging/services/messaging_api_service.dart` + `lib/messaging/screens/new_conversation_page.dart` — used exclusively for messaging's "New Conversation" member picker, not by any Members Directory UI (which doesn't call any API at all). Response parsed as raw `Map<String,dynamic>` per result (no `Member` model exists in the codebase) — fields read: `id`, `name`, `avatar_urls.thumb`. 🟡 High confidence this reflects the real shape (the app works, per the messaging audit's own confirmation) but no independently captured raw response exists for this endpoint specifically.

**No `GET /buddyboss/v1/members` call exists anywhere for the standalone directory** — `members_page.dart` never touches the network.

## Models to create/change
No `Member`/`MemberProfile` model exists at all. `messaging`'s search results are handled as untyped `Map<String, dynamic>`. A dedicated model would be needed for the Members Directory (and could be shared with messaging's search, consolidating the untyped map usage — see Architectural Opportunity below).

There's also a separate, apparently-dead `UserModel`/`UserProfilePage` (`lib/models/user_model.dart`, `lib/Profile/user_profile_page.dart`) that takes a `UserModel` directly and renders `AssetImage(user.profileImage)` (a **local asset**, not a network image) — this looks like early scaffold/mock code, not wired to anything real. Not confirmed dead (no reference search performed yet), but its `AssetImage`-based avatar is a strong signal it was never connected to live data.

## Functional Behavior

**Business rules / validation:** none observable — the entire UI is static.

**UI interactions:** four tabs ("All Members," "My Connections," "Following," "Followers") — ✅ Confirmed the tab switch itself works (`selectedTab` state toggles, visual underline changes), but 🔴 Hypothesis/**Confirmed Bug candidate**: switching tabs never re-filters the `members` list (it's the same 3 hardcoded entries regardless of selected tab) — so the tabs are visually functional but behaviorally inert.

**Search bar:** present, styled, `hintText: "Search members"` — ✅ Confirmed no `onChanged`/controller/state wiring at all (plain `TextField` with only a decoration, per direct code read). Fully decorative, same pattern as the Activity Feed's home-page search bar.

**Filter icon button:** `IconButton` in the header, `onPressed` contains only `// Search filter later` — decorative.

**Sort dropdown ("Recently Active"):** static `Row` with text + icon, no `onTap`/`PopupMenuButton` — decorative, not even a stub interaction.

**Member card action buttons:** four icons per card — Follow (`person_add_alt`), Message (`chat_bubble_outline`), Call (`call_outlined`), Video Call (`videocam_outlined`) — **all four are empty `onPressed` stubs** (`// Follow action`, `// Message action`, `// Call action`, `// Video call action`). Notably, the app already has a **working** message-start flow (`MessagingRepository.findOrCreateThreadWith`, used successfully elsewhere) that this Message button could call — it's not wired to it at all.

**Card tap:** ✅ Confirmed via grep — no `onTap`/`GestureDetector`/`Navigator` exists on the member card itself. Tapping a member does nothing; there's no path from this screen to any profile view.

**Presence indicator:** each card shows a static green dot (`Positioned` circle, hardcoded color) — not tied to any real online/offline state (no `status` field read from the dummy data map, the dot is unconditionally green for all three entries).

**State machine:** none — no loading/error/empty states exist because there's no async operation at all. This is a meaningfully different situation from Activity Feed (which has a real, working `FutureBuilder` state machine, just missing features) — Members Directory has no state machine to speak of.

**Pagination:** N/A — fixed 3-item hardcoded list, "97 Members" header count is also hardcoded text, unrelated to the list's actual length.

## Role / Account-Status Variations
Not tested — and not meaningfully testable given zero API wiring exists yet.

## Undocumented / Plugin-Specific Behavior
`members/presence` (POST) — exists, purpose unconfirmed (push local presence state? distinct from the Heartbeat-delivered `users_presence` snapshot documented in `notifications.md`?). `members/me/permissions` — exists, unconfirmed what it returns. `members/action/{id}` — exists, unconfirmed which actions it supports (follow/block are plausible given the pattern from `activity/action`).

## Open Questions
- Response schema for `GET /buddyboss/v1/members` (list) and `/members/{id}` (detail) — no raw capture exists.
- What does `members/action/{id}` actually do — is this where Follow/Block live?
- What's the relationship between `members/presence` and Heartbeat's `users_presence`?
- Full set of valid `scope`/`filter`/`order_by` values for the website's `members_filter` AJAX action.
- Is `UserModel`/`UserProfilePage` genuinely dead code, or referenced somewhere not yet found?

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Members Directory tabs | Four tabs suggest four distinct filtered views | All four tabs render the identical hardcoded 3-item list; `selectedTab` state changes but never affects `members` | **UI-only Placeholder** |
| 2 | Member card action buttons (Follow/Message/Call/Video) | Icons suggest working actions, especially Message given messaging is confirmed to work elsewhere in the app | All four are empty `onPressed` stubs; Message specifically doesn't call the already-working `findOrCreateThreadWith` | **UI-only Placeholder** (×4) — Message is the most notable since the working plumbing already exists elsewhere in the codebase and simply isn't connected here |
| 3 | Card tap → profile navigation | Reasonable to assume tapping a member opens their profile, mirroring `PostCard`'s avatar/name tap-through to `ProfilePage` | Confirmed via grep: no tap handler exists on the member card at all | **Missing Feature** |
| 4 | Presence dot | Green dot per card implies live online-status data | Unconditionally green for all entries, not tied to any field | **UI-only Placeholder** |

## Parity Scorecard

**Capability list this score is computed from** (10 capabilities, derived from the confirmed `buddyboss/v1/members` route surface + the app's own messaging-search precedent): browse all members, search members, filter by scope (following/etc.), sort/order, pagination, view member detail/profile, follow/unfollow, message a member, presence indicator, avatar/cover view.

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **0 of 10** = **0%** — even search, which works elsewhere in the app (messaging), isn't wired into this screen at all
- **Parity:** 0%
- **Confirmed Bugs:** 0 (nothing here is broken — it's all inert-by-construction, which is Missing Feature / UI-only Placeholder territory, not a regression in working code, unlike Activity Feed's two real bugs)
- **Missing Features:** 9 (browse-with-real-data, filter, sort, pagination, view profile, follow, call, video call — search is technically *possible* via existing app code but not wired here, counted as missing for this screen specifically)
- **Decorative UI:** 8 (filter icon, sort dropdown, 4 card action buttons, presence dot, tab-switching-without-effect)
- **API Coverage:** 0 of 12 confirmed `buddyboss/v1/members` routes called by this screen (0%) — though `GET /members?search=` is called elsewhere in the app (messaging), so the *codebase* isn't at 0%, this *feature* is
- **Evidence Confidence:** ✅ 7 (dummy data confirmed, all decorative handlers confirmed via direct code read, no-navigation confirmed via grep, working search endpoint's shape confirmed via messaging) / 🟡 1 (search endpoint's exact response fields, inferred not independently captured) / 🔴 4 (all unexercised endpoint response shapes, `members/action` semantics, `members/presence` purpose, `UserModel` dead-code status) → **(7 + 0.5)/12 ≈ 63%**
