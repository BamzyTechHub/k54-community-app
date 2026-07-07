# Feature: Notifications

## Status
- **Website:** Partial. Confirmed via `.claude/k54global.com HAR2.har` (2026-07-07) — notification data flows through the generic WP Heartbeat mechanism (`admin-ajax.php`, `action=heartbeat`), not a dedicated notifications-fetch endpoint observed yet. Real content examples confirmed, full HTML fragments captured. `GET /buddyboss/v1/notifications` (the REST route) not yet exercised on the website side — unconfirmed whether the website's own notification page/dropdown uses this REST route for anything (e.g. a "view all" page) alongside the heartbeat-delivered live badge.
- **Flutter:** Not implemented (no API wiring, confirmed from repo) — but **notably more built-out than Members/Friends/Groups' dummy screens**: mark-as-read (tap or "Mark all read"), empty state, and read/unread visual state all work correctly against local `setState`, just never connected to a server. See Functional Behavior.
- **Figma:** Not yet reviewed.

## Network Behavior

Source: `.claude/k54global.com HAR2.har`, entry 0, captured 2026-07-07 ~09:45 UTC.

```
POST /wp-admin/admin-ajax.php
Content-Type: application/x-www-form-urlencoded
Body: _tutor_nonce={nonce}&data[onScreenNotifications]=true&data[presence_users]={csv of user IDs}
      &data[customfield]=&data[bp_activity_last_recorded]={unix ts}&data[bp_activity_last_recorded_search_terms]=
      &data[bp_heartbeat][topic_id]=&data[bp_heartbeat][scope]=all&data[bp_heartbeat][order_by]=date_recorded
      &interval=60&_nonce={nonce}&action=heartbeat&screen_id=front&has_focus=false

Response 200, application/json:
{
  "users_presence": [{"id": 5, "status": "online"}, {"id": 1, "status": "offline"}, ...],
  "on_screen_notifications": "<html — <li> fragments, one per notification>",
  "total_notifications": 58,
  "unread_notifications": "<html — <li> fragments, unread subset>",
  "unread_messages": "<html — <li> fragments for unread message threads>",
  "wp-auth-check": true,
  "server_time": 1783419932
}
```

This is WP core's Heartbeat API being used by BuddyBoss/BuddyPress as the transport for live notification delivery — **not a bespoke notifications-polling endpoint**. The website's notification bell/badge is populated by parsing/injecting these HTML fragments directly into the DOM, not by consuming structured JSON and rendering it client-side. This is a fundamentally different approach than what the app would need to do (the app needs structured data — real field values — not pre-rendered HTML), so this response can't be used as-is; it does, however, confirm real content/examples and the numeric total.

### Confirmed real notification examples (verbatim from the payload, not fabricated)
- Message notification: *"Ezekiel sent you a message: "did it get there""* → links to `https://k54global.com/messenger/?thread_id=3`
- Activity-post notification: *"Ezekiel posted an update: "GOOD MORNING EVERYONE 🙏""* → links to `https://k54global.com/news-feed/p/{id}/?rid={id}`

Each `<li>` carries `class="read-item unread"` (or presumably without `unread` once read — not confirmed, no read example captured), a notification-avatar block linking to the actor's profile (`/members/{slug}/`, see below), and for message notifications specifically, `data-thread-id="{id}"` plus an inline presence indicator (`<span class="member-status online" data-bb-user-id="5" data-bb-user-presence="online">`).

### Not yet confirmed
- Whether `GET /buddyboss/v1/notifications` (the documented REST route) returns comparable structured data, or something else entirely — not yet called against this site.
- Mark-as-read behavior — no read/unread transition observed in this capture.
- Notification types beyond "message" and "activity post" (mentions, group invites, friend requests, comments, etc.) — none of those appeared in this specific payload.
- Pagination — `total_notifications: 58` is a large number; how the "view all" experience paginates through them is unconfirmed.

### Website — full REST surface (✅ Confirmed to exist via `GET /wp-json/`, 🔴 Hypothesis for response bodies)
```
GET,POST                       /buddyboss/v1/notifications
GET,POST,PUT,PATCH,DELETE      /buddyboss/v1/notifications/{id}
POST,PUT,PATCH                 /buddyboss/v1/notifications/bulk/read
```
A dedicated bulk-mark-read endpoint exists — directly relevant, since the app's dummy "Mark all read" button already has the right *interaction* built, just nothing to call.

### App — none
No notifications API call exists anywhere in the codebase. `lib/Notifications/notifications_page.dart` imports only `flutter/material.dart` — confirmed no `ApiService`/`BuddyBossService` reference at all.

## Models to create/change
No `Notification` model exists — the dummy list is `List<Map<String, dynamic>>` with `title`, `time`, `icon` (a literal `IconData`, not a server-derivable value), `color`, `isRead`. A real model needs to map server notification *types* to icons/colors client-side (the server won't send a Flutter `IconData`), and needs a deep-link target field (see below) that the dummy model has no equivalent for at all.

## Functional Behavior

**Client-side logic not obvious from the API:** the website appears to parse pre-rendered HTML `<li>` fragments out of a heartbeat JSON payload and inject them into the DOM — an approach the Flutter app cannot replicate directly (it needs the REST route's structured JSON instead, assuming that route returns comparable data — unconfirmed).

**Flutter-side interaction, confirmed working against local state only:** tapping a notification sets `isRead = true` via `setState` (background color and a green unread-dot both update correctly); "Mark all read" iterates the whole list the same way; empty state ("No notifications") is a real, correctly-gated branch (`notifications.isEmpty ? ... : ListView.builder(...)`). This is meaningfully more built than Members/Friends/Groups' inert dummy screens — the interaction patterns already exist and are correct, they're just never backed by a server call. Wiring real data in should be cheaper here than for those three features.

**Deep links: confirmed entirely absent.** Tapping a notification only mutates local read-state — there's no `Navigator` call anywhere in the file, so a "commented on your post" notification doesn't go to the post, a "sent you a connection request" notification doesn't go to Friends, etc. Matches the website's confirmed real behavior of linking notifications to specific content (`/messenger/?thread_id=3`, `/news-feed/p/{id}/?rid={id}` — see above) — the app has no equivalent mechanism at all, not even a stub.

**Notification bell badge:** `home_page.dart`'s notification icon (`Icons.notifications_outlined`) navigates to `NotificationsPage` unconditionally, with **no unread-count badge** — confirmed by contrast with the adjacent Messages icon, which is wrapped in `UnreadBadge` (a real, working component from the messaging module). The badge infrastructure already exists in the codebase and simply isn't reused here.

**Server-side assumptions inferred:** the "unread_messages" and "on_screen_notifications" fields being separate from a single unified "notifications" concept suggests messages are treated as a distinct sub-type of notification server-side, consistent with how Better Messages/BuddyPress messaging is generally a separate component from core BuddyPress notifications.

**Edge cases:** `total_notifications: 58` with no visible pagination mechanism in this capture — worth checking whether the "on_screen_notifications"/"unread_notifications" HTML strings are capped at some count (33799 and 35346 chars respectively suggests many `<li>` items, but not necessarily all 58).

## Role / Account-Status Variations

Not tested — single account only.

## Undocumented / Plugin-Specific Behavior

The heartbeat's `data[bp_heartbeat]` sub-object (`topic_id`, `scope=all`, `order_by=date_recorded`) looks like a BuddyPress-specific extension of WP core Heartbeat, used simultaneously for the activity-feed "new items" banner (see `activity-feed.md`) and notifications — the same single heartbeat call appears to serve multiple unrelated UI features at once (presence, notifications, unread messages, activity-feed freshness) rather than each feature polling independently. Confirmed by this one payload containing all of the above simultaneously; not traced further than that.

## Open Questions

- Does the REST route `/buddyboss/v1/notifications` return anything usable, or is heartbeat-delivered HTML the only real mechanism the website itself relies on?
- How does mark-as-read work on the website — via `notifications/bulk/read`/`notifications/{id}`, or a legacy admin-ajax action? Route existence is confirmed, actual usage isn't.
- What other notification types exist beyond message/activity-post?
- Confirm whether `lib/models/post_model.dart`'s numeric-ID profile link (`/members/{user_id}`) actually resolves, given the real profile URL format uses a slug (`/members/{slug}/`).

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Notifications feature overall | `CLAUDE.md`/pre-audit: "Not implemented — hardcoded dummy list" | Confirmed accurate for data/API — but the dummy screen's *interactivity* (mark-read, empty state) is real, working local behavior, not itself fake. No drift on the "not implemented" claim, but worth noting this feature isn't as inert as the label suggests. | N/A — confirms prior flag with added nuance |
| 2 | Notification bell badge | Reasonable to expect it mirrors the Messages icon's unread badge, since that component already exists and works | `UnreadBadge` is used on the Messages icon in `home_page.dart` but not the Notifications icon — the reusable piece exists and simply isn't applied here | **Missing Feature** (cheap one — see `architecture-recommendations.md`) |
| 3 | Notification deep links | Website confirmed to link notifications to specific content (thread, activity post) | App's notifications have no navigation at all, not even a stub — tapping only changes local read-state | **Missing Feature** |

## Parity Scorecard

**Capability list this score is computed from** (7 capabilities): view notification list, mark single read, mark all read, empty state, unread badge on entry point, deep-link to source content, notification-type coverage (message/activity/mention/friend-request/etc.).

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **2 of 7** (mark single read, mark all read — both genuinely functional, just against local dummy data, not fetched data) = **29%**. View list/empty-state don't count as real capability since the data itself is fake, not fetched.
- **Parity:** 29% — highest of the four 0%-adjacent features audited so far (Members/Friends/Groups), because of the working local interaction layer
- **Confirmed Bugs:** 0
- **Missing Features:** 4 (real data fetch, unread badge on entry icon, deep links, notification-type/icon mapping from server data)
- **Decorative UI:** 0 — unusual for this audit so far: everything visible actually works, it's just disconnected from a server, not fake-but-inert
- **API Coverage:** 0 of 3 confirmed `buddyboss/v1/notifications` routes called (0%)
- **Evidence Confidence:** ✅ 8 (full heartbeat response captured with real content, route existence confirmed, app's local interactivity confirmed via direct read, no-badge contrast confirmed against `UnreadBadge`'s real usage elsewhere, no-deep-link confirmed via direct read) / 🟡 1 (whether `bulk/read`/`notifications/{id}` are really how mark-as-read works on the website) / 🔴 3 (REST route's actual response shape, other notification types, website's read-transition mechanism) → **(8 + 0.5)/12 ≈ 71%**
