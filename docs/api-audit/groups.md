# Feature: Groups

## Status
- **Website:** Partial. Legacy `admin-ajax.php` (`groups_filter`, `groups_join_group`) request shape confirmed via HAR1, no response body. Full `buddyboss/v1/groups` (16 routes) + forums/topics/reply surface (bbPress-style, 17 more routes across `forums`/`bb-topics`/`topics`/`reply`) confirmed via route index. Group forums existence corroborated independently by wp-admin's own "4 Forums, 19 Discussions, 25 Replies" count (`plugin-inventory.md`).
- **Flutter:** Confirmed via direct code reading — **both** group surfaces are 100% dummy data with zero API wiring and zero card-level navigation, confirmed via grep. They show genuinely different fake datasets and different card designs, not just duplicated code — reinforcing that the "which one is real" question is a product decision, not a trivial dedup.
- **Figma:** Not yet reviewed.

## Network Behavior

### Website — legacy AJAX (✅ Confirmed request shape, 🔴 Hypothesis for response — `.claude/k54global.com.har`)
```
action=groups_filter        scope=personal, filter=active, search_terms=, page=1, order_by=, method=reset
action=groups_join_group    item_id=13, component=groups, button_clicked=secondary
```
Same pattern as members/activity: nonce as a POST field (`nonce`, `_wpnonce`), not the `X-WP-Nonce` header. No response body captured for either action.

### Website — full REST surface, groups (✅ Confirmed to exist, 🔴 Hypothesis for all response bodies)
```
GET,POST                     /buddyboss/v1/groups
GET,POST,PUT,PATCH,DELETE    /buddyboss/v1/groups/{id}
GET                          /buddyboss/v1/groups/{id}/detail
GET                          /buddyboss/v1/groups/{id}/info
GET,POST,PUT,PATCH           /buddyboss/v1/groups/{id}/settings
GET,POST,DELETE              /buddyboss/v1/groups/{id}/avatar
GET,POST,DELETE              /buddyboss/v1/groups/{id}/cover
GET,POST                     /buddyboss/v1/groups/{id}/members
POST,PUT,PATCH,DELETE        /buddyboss/v1/groups/{id}/members/{user_id}
GET,POST                     /buddyboss/v1/groups/invites
GET,POST,PUT,PATCH,DELETE    /buddyboss/v1/groups/invites/{invite_id}
POST                         /buddyboss/v1/groups/invites/multiple
GET,POST                     /buddyboss/v1/groups/membership-requests
GET,POST,PUT,PATCH,DELETE    /buddyboss/v1/groups/membership-requests/{request_id}
GET                          /buddyboss/v1/groups/details
GET                          /buddyboss/v1/groups/types
```
Confirms private-group membership requests are a distinct resource from invites (separate `membership-requests` endpoints vs. `invites`) — matches the dummy data's "Private • Group" entry, a real distinction the mock data happens to gesture at without implementing.

### Website — forums (bbPress-style, ✅ Confirmed to exist)
```
GET,POST                     /buddyboss/v1/forums          GET /forums/{id}   GET /forums/link-preview
POST,PUT,PATCH               /buddyboss/v1/forums/subscribe/{id}
GET,POST                     /buddyboss/v1/bb-topics       + /bb-topics/{id}  + /bb-topics/order
GET,POST                     /buddyboss/v1/topics          + /topics/{id} + /topics/action/{id} + /topics/dropdown/{id} + /topics/merge/{id} + /topics/split/{id}
GET,POST                     /buddyboss/v1/reply           + /reply/{id} + /reply/action/{id} + /reply/move/{id}
```
`topics/merge`/`topics/split`/`reply/move` are moderator-tooling endpoints (merging/splitting discussion threads, moving replies between topics) — confirms real forum moderation capability exists, not just basic post/reply. `forums/subscribe` confirms per-forum notification subscriptions. None of this is referenced anywhere in the app (no forum UI exists at all, confirmed by absence — no `forum`/`topic`/`reply` files found in `lib/`).

### App — none
No groups-related API call exists anywhere in the codebase — neither `screen/groups_page.dart` nor `communication/groups_page.dart` makes any network request.

## Models to create/change
No `Group` model exists — both screens use raw `Map<String, dynamic>`/`Map<String, String>` dummy literals, two different shapes for the same nominal concept (one has `cover`/`logo`/`isOwner`/`button`; the other has `image`/`members`/`status`) — neither maps cleanly onto the confirmed REST schema's likely fields, so a real implementation starts from the API shape, not either existing mock.

## Functional Behavior

**Two surfaces, both fully decorative, confirmed distinct:**
- `lib/screen/groups_page.dart` (main bottom-nav tab) — 3 tabs ("All Groups"/"My Groups"/"**Create a Group**" — note the third tab is itself an odd pattern, a tab that should presumably be an action/navigation trigger, not a filterable view; confirmed the tab switch only toggles visual selection, never changes the rendered list). Search bar and filter icon both decorative (`// Filter options later`). Sort dropdown ("Recently Active") is static, no `onTap`. Each card shows cover image, logo, a 3-avatar "members" stack (hardcoded colored circles, not real avatars) + "..." overflow indicator, and a Join/Organizer button whose style (filled green "Organizer" with a check icon vs. outlined "Join Group" with a plus icon) is driven by a per-item `isOwner` bool in the dummy data — a real, if currently fake, permission-conditional UI pattern worth preserving when rebuilt.
- `lib/communication/groups_page.dart` (CommunicationNavigation tab) — simpler: header search/create/call icons all decorative, flat list with a status badge (Active/New, colored). **Zero navigation of any kind** — confirmed via grep, no `GestureDetector`/`InkWell`/`Navigator`/`onTap` anywhere in the file at all, not even a tab switcher.

**Neither screen has any tap target on the group card itself** — confirmed via grep on both files (the only `onTap` found anywhere is `screen/groups_page.dart`'s tab switcher). No path from either screen to a group detail/feed view.

**State machine:** none in either file — no async operation exists.

**Group forums, moderation, and media** (per the user's original sub-item list) have **zero UI presence** in the app — same absence pattern as Friends' request/accept-reject UI. Not decorative, just absent.

## Role / Account-Status Variations
Not tested. The `isOwner`-driven button styling in `screen/groups_page.dart` is the one piece of the UI that already anticipates role-conditional rendering, even though it's currently fed by hardcoded dummy booleans rather than real membership-role data.

## Undocumented / Plugin-Specific Behavior
Whether the website's own group pages use this REST API or (matching the platform-wide pattern established for messaging/members/activity) legacy `admin-ajax.php` for everything beyond `groups_filter`/`groups_join_group` — not captured beyond those two actions.

## Open Questions
- Full response schema for any `groups` endpoint — none captured.
- Are the two Flutter surfaces meant to be the same feature (dedup candidate) or genuinely different ("all groups you could join" vs. "your groups quick-access")? This remains a product decision, not resolved by this audit — see `feature-inventory.md`'s original flag.
- What triggers a `membership-requests` flow vs. an `invites` flow — is this simply public-vs-private group joining, or a more nuanced distinction?
- Does the website's own UI expose forum moderation (merge/split/move) to regular members or only admins/moderators?

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Two Groups surfaces | `CLAUDE.md`/pre-audit: flagged as unreconciled, unclear if same feature | Confirmed via code read: genuinely different dummy datasets and card designs (not copy-pasted), both fully decorative, both zero-API — the flag was accurate, now with concrete detail on exactly how they differ | N/A — confirms prior flag, adds detail, no drift |
| 2 | "Create a Group" as a tab | Reasonable to assume a group-creation flow exists behind it | It's a tab like any other in `screen/groups_page.dart` — selecting it just changes tab-underline state, renders the same static list, no create form exists anywhere | **UI-only Placeholder** |
| 3 | Group forums/moderation | Not previously scoped as part of "Groups" in the app's dummy screens at all | 17 real, confirmed REST routes exist (forums, topics, reply, incl. merge/split/move moderation tools) with zero corresponding UI anywhere in the app | **Missing Feature** — a larger one than either dummy screen's own gaps suggest, since neither screen even gestures at forums |

## Parity Scorecard

**Capability list this score is computed from** (14 capabilities, derived from the confirmed `groups` + forums route surface): browse/discover groups, search, filter/sort, view group detail, join (public), request membership (private), leave, view group feed, view members list, invite members, group settings (owner), avatar/cover upload, forum browse+post, forum moderation (merge/split/move).

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **0 of 14** = **0%**
- **Parity:** 0%
- **Confirmed Bugs:** 0 (inert by construction, same reasoning as Members/Friends)
- **Missing Features:** 14 (all of them)
- **Decorative UI:** 11 (search, filter, sort dropdown, 3 tabs incl. the misleading "Create a Group" tab, Join/Organizer button, in `screen/groups_page.dart`; search, create, call icons in `communication/groups_page.dart`) — plus zero navigation on either screen counted separately in the Discrepancy Log rather than double-counted here
- **API Coverage:** 0 of 16 confirmed `groups` routes + 0 of 17 confirmed forums-adjacent routes called (0%)
- **Evidence Confidence:** ✅ 6 (both dummy datasets confirmed distinct via direct read, zero navigation confirmed via grep on both files, request shapes for the 2 legacy actions confirmed via HAR1, route existence confirmed via REST index, forum-count cross-confirmed via wp-admin At a Glance) / 🟡 1 (whether the two surfaces are intentionally different — inferred from content differences, not confirmed by a product decision) / 🔴 3 (all response schemas, website's own transport for groups beyond the 2 captured actions, forum moderation's actual permission model) → **(6 + 0.5)/10 ≈ 65%**
