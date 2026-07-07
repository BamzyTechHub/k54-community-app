# Plugin Inventory

Source: WP Admin → Plugins screenshot, captured 2026-07-07. This is direct admin-panel evidence — treated as **Confirmed**, not inferred.

WordPress 7.0, BuddyBoss theme (per Dashboard "At a Glance").

## Directly relevant to K54 app parity

| Plugin | Version | Relevance |
|---|---|---|
| BuddyBoss Platform | 3.0.5 (update available: 3.1.0) | Core — REST API + website UI backbone |
| BuddyBoss Platform Pro | 3.0.2 | Premium features layered on Platform — need to determine which app-relevant features are Pro-gated |
| BuddyBoss Sharing | 2.0.1 | Social share buttons on activity/content — not currently in app |
| **Better Messages** | 2.15.13 (update available: 2.15.16) | Base plugin — website's actual `/messenger/` UI. **Not** what the app's REST calls use. |
| **Better Messages - WebSocket Version** | 2.15.14 (update available: 2.15.16) | Real-time transport add-on for Better Messages. Confirms a WS layer exists/is installed — **does not yet confirm a live WS connection was observed** (see HAR findings below: no `_webSocketMessages` captured in first HAR, open question). |
| **Better Messages - Voice Messages** | 1.3.3 | Voice message addon. **Corrects an assumption in `K54_PROJECT_HANDOFF.md` Section 7**, which stated voice notes have "no plugin support for this UI pattern specifically" — that's now known to be wrong; a dedicated official addon exists and is installed. Whether it's *active* and *exposes any endpoint the app could use* is still unconfirmed. |
| JWT Authentication for WP-API | 1.5.0, by Enrique Chavez | Confirms the exact plugin identity. This is the well-known fork whose auth failures return **HTTP 403** (not 401) with codes like `[jwt_auth] invalid_username`/`invalid_password` — relevant context for documenting login error responses later. |
| Nextend Social Login | 3.1.25 | Facebook/Google/X social login — **confirmed active on the website**. The Flutter app's `login.dart` has decorative "Continue with Google"/"Continue with Facebook" buttons that just show a "will be connected later" snackbar. This is a real, confirmed parity gap as of this plugin evidence alone, no HAR needed to establish that the website-side feature exists. |
| Members | 3.2.22, by MemberPress | Role/capability management — "edit roles and capabilities, clone existing roles, assign multiple roles per user, block post content, or even make your site completely private." Strongly suggests **custom roles beyond WP defaults** exist on this site. Any "Role / Account-Status Variations" documentation must check actual configured roles (Users → Roles in wp-admin) rather than assuming Administrator/Subscriber only. |
| LearnPress | 4.4.1, by ThimPress | LMS plugin — confirmed active |
| LearnPress - BuddyPress Integration | 4.0.3, by ThimPress | Integrates LearnPress with BuddyPress profiles |
| **Tutor LMS** | 3.9.14, by Themeum | **Second, separate LMS plugin, also active.** Both LearnPress and Tutor LMS are installed simultaneously — open question below on which actually backs the live Courses feature. |
| WpStream - Live Streaming, VOD, PPV | 4.12.3 | Confirms a whole feature area (live streaming/VOD/pay-per-view) not currently in the app or feature inventory at all — matches "Free-To-View Live Channels" / "Free-To-View VODs" nav items visible in the Dashboard sidebar. |
| The Events Calendar | 6.16.5 | Confirms an Events feature area, also not currently in the app or feature inventory. |
| Inactive Logout | 3.6.2 | Auto-logs-out idle sessions — relevant to website session/nonce lifetime behavior, not the app's JWT flow directly. |

## Present but not app-relevant (noise, noted for completeness)

Code Snippets, Hostinger AI, Hostinger Easy Onboarding, Hostinger Reach, Hostinger Tools, Image Optimizer, LiteSpeed Cache, Live News, Location Weather, Nextend Social Login *(listed above — is relevant)*, Site Kit by Google, UpdraftPlus, WP Staging, WpStream *(listed above)*.

`message-hub.hostinger.com` traffic seen in the first HAR (see `messaging-better-messages.md`) is Hostinger's own AI assistant widget (matches "Hostinger AI"/"Hostinger Reach" plugins) — unrelated to BuddyBoss/Better Messages/K54, filtered out of messaging documentation.

## Open questions raised by this inventory

- **Which LMS plugin (LearnPress or Tutor LMS) actually backs the live-site Courses experience members see?** Both are active. Needs a Courses-page capture to determine which one's frontend is actually rendered/used, or whether they serve different purposes (e.g. one for a specific program, one general).
- **Is Better Messages' WebSocket Version add-on actually delivering a live connection in practice**, or does the site fall back to REST polling (`checkNew`)? First HAR (see `messaging-better-messages.md`) shows no captured WebSocket handshake — needs an explicit check of DevTools' "WS" filter to confirm either way.
- **What do BuddyBoss Platform Pro's premium features actually add** that's relevant to app parity? Not yet investigated.
- **What custom roles exist** (via the Members plugin)? Needs a check of Users → Roles in wp-admin.
- Are the "calling.mp3"/"dialing.mp3" sound assets (found in the WebSocket plugin's asset folder, see `messaging-better-messages.md`) evidence of an actual voice/video calling feature, or just bundled/unused addon assets? Not yet confirmed either way — flagging, not concluding.
