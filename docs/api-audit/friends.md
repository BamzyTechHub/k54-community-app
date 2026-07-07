# Feature: Friends / Connections

## Status
- **Website:** Partial. Full `buddyboss/v1/friends` REST surface confirmed via route index (2 routes — small, RESTful design). No response bodies or website UI behavior captured yet.
- **Flutter:** Confirmed via direct code reading — `lib/communication/friends_page.dart` is 100% hardcoded dummy data, zero API wiring, zero navigation (confirmed via grep — no `GestureDetector`/`InkWell`/`Navigator` anywhere in the file). Even less built than Members Directory: there isn't so much as a decorative UI for friend requests, accept/reject, or removal — those concepts have **no presence at all** in the app, not even fake buttons.
- **Figma:** Not yet reviewed.

## Network Behavior

### Website — confirmed via `GET /wp-json/` (existence only, no bodies captured)
```
GET,POST,DELETE             /buddyboss/v1/friends
GET,POST,PUT,PATCH,DELETE   /buddyboss/v1/friends/{id}
```
Compact, RESTful design confirmed: no separate "send request"/"accept"/"reject" endpoints exist — `POST /friends` is very likely "send a request," and `PUT/PATCH /friends/{id}` is very likely how a pending request transitions to accepted (updating the friendship resource's status), with `DELETE` covering both "reject a pending request" and "remove an existing friend." This is an inference from the route shape (🟡 High confidence — the pattern is standard REST and matches how `buddyboss/v1/activity`'s single-resource CRUD routes work), not confirmed by any observed request/response.

Legacy `admin-ajax.php` friends-related actions (if any — messaging/groups/members/activity all confirmed to use `action=` params for their website UI) have not been captured; no HAR session happened to include a friends interaction.

### App — none
No friends-related API call exists anywhere in the codebase. Confirmed via grep: `Friend` (the one model that exists for this feature) is referenced only in its own definition file — genuinely dead code, matching `CLAUDE.md`'s existing dead-code flag for `lib/models/friend_model.dart`.

## Models to create/change
`Friend` (`lib/models/friend_model.dart`) exists but is unused dead code (`id`, `name`, `image`, `isOnline` — no status field for pending/accepted/blocked, so even if revived it couldn't represent a friend *request*, only an established friendship). A real implementation needs a model that can represent request state, not just "is friend."

## Functional Behavior

**UI interactions (all confirmed decorative via direct code read):**
- Header: search icon (`// Search friends later`), video-call icon (`// Group video call later`), phone-call icon (`// Group call later`) — all empty.
- Per-friend row: Add Friend, Voice Call, Video Call icon buttons — all empty (`// ... action later` comments).
- **Notable content/logic mismatch:** every dummy entry shows an "Add Friend" button despite the screen being titled "Friends" and presumably representing people already connected — even as placeholder content, the button choice doesn't match the list's own premise. Minor, but worth noting as the kind of detail that'd need resolving during a real build, not just wiring up an API.
- No card is tappable at all — confirmed via grep, no tap target exists on the friend row.

**Friend requests, accept/reject, mutual state:** **zero UI presence** — not decorative buttons, not TODO stubs, nothing. This is a more complete absence than any other feature audited so far (Members Directory and Activity Feed at least have placeholder controls for most concepts).

**State machine:** none — same as Members Directory, no async operation exists so there's no loading/error/empty state to speak of.

## Role / Account-Status Variations
Not tested — not meaningfully testable given zero API wiring.

## Undocumented / Plugin-Specific Behavior
Whether `PUT`/`PATCH /friends/{id}` is really how accept works, or whether there's a distinct action parameter (mirroring `activity/{id}` and `members/action/{id}`'s pattern), is unconfirmed — flagged as inference, not fact.

## Open Questions
- Full request/response schema for all `friends` endpoints — none captured.
- Does the website's own friends UI use this REST API, or (like messaging/groups/members/activity) a legacy `admin-ajax.php` action instead? Not yet captured — given the established platform-wide pattern, the legacy-AJAX path is the more likely default assumption, but this should be confirmed with a real capture, not assumed.
- What does "mutual connections" or a mutual-friends-count concept look like via this API, if it exists at all?
- Is there a friend-request notification tie-in (via the Heartbeat-delivered notifications documented in `notifications.md`)?

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Friends feature overall | `CLAUDE.md`/`feature-inventory.md` (pre-audit): "Not implemented — hardcoded dummy data" | Confirmed exactly as previously stated — no drift here, this is the one feature so far where the pre-audit description matched the code exactly | N/A — noted for completeness, not a discrepancy |
| 2 | "Add Friend" button on existing friends | Implied the list represents current connections | Every entry shows an Add-Friend affordance, logically inconsistent with a "Friends" list | **UI-only Placeholder** (content-logic mismatch, not just non-functional) |
| 3 | Friend requests / accept-reject | Plausible this exists somewhere in the app given the feature name | Zero UI presence anywhere in the codebase — not a stub, not a placeholder, absent entirely | **Missing Feature** |

## Parity Scorecard

**Capability list this score is computed from** (7 capabilities, derived from the confirmed 2-route API + standard friends-feature expectations): view friends list, send friend request, accept request, reject request, remove/unfriend, view pending requests, mutual-friends indicator.

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **0 of 7** = **0%**
- **Parity:** 0%
- **Confirmed Bugs:** 0 (same reasoning as Members Directory — inert by construction, not a regression)
- **Missing Features:** 7 (all of them)
- **Decorative UI:** 7 (3 header icons, 3 per-row icons, plus the content-logic mismatch counted separately as its own discrepancy)
- **API Coverage:** 0 of 2 confirmed routes called (0%)
- **Evidence Confidence:** ✅ 5 (dummy data confirmed, no navigation confirmed via grep, `Friend` dead-code status confirmed via grep, all decorative handlers confirmed via direct read, pre-audit description confirmed accurate) / 🟡 1 (accept/reject-via-PATCH inference from route shape) / 🔴 3 (full response schemas, website's own transport mechanism for this feature, mutual-friends concept) → **(5 + 0.5)/9 ≈ 61%**
