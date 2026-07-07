# REST Namespace → Plugin Dependency Map

Every namespace from the full platform route index (`rest-route-index.md`, 842 routes, `GET /wp-json/`, fetched 2026-07-07), mapped to its owning plugin, purpose, authentication method, and current Flutter usage. This is the single place to check "which plugin does this feature ultimately depend on, and does the app already talk to it."

**Auth column legend:** `Confirmed` = directly tested (curl or captured live traffic). `Standard WP` = inferred from being a normal WP REST namespace, not individually tested. `Own system` = confirmed or strongly suggested to have its own separate auth (e.g. a `token` sub-resource), not compatible with the site's JWT by default. `Unknown` = no evidence either way.

**Flutter usage column:** `Uses` = confirmed in current app code. `Partial` = some endpoints in the namespace are used, most aren't. `None` = not called anywhere in the app.

| Namespace | Owning plugin | Purpose | Auth method | Flutter usage |
|---|---|---|---|---|
| `jwt-auth/v1` | JWT Authentication for WP-API (Enrique Chavez) | Issues the app's bearer tokens | Own system (username/password → token) | **Uses** — the app's entire auth flow |
| `buddyboss/v1` | BuddyBoss Platform (+ Pro) | Core social platform: activity, groups, members, xprofile, messages, forums, media, document, video, polls, notifications, friends, moderation, reactions, mentions, subscriptions, pusher, signup, invites | JWT Bearer — **Confirmed** (app already uses successfully for messages, xprofile, members, signup, activity/favorite) | **Partial** — messages, members search, xprofile update, activity feed + favorite, signup, members/me are used; groups, friends, forums, video, polls, notifications, moderation, reactions, pusher, subscriptions are not |
| `better-messages/v1` | Better Messages (+ WebSocket + Voice Messages add-ons) | Website's actual messaging system: threads, calls, AI bots/translation/transcription, reactions, pins, push notifications | JWT Bearer — **Confirmed** for GET + POST (2026-07-07 curl tests); `X-WP-Nonce` also works for browser sessions | **None** — app uses `buddyboss/v1/messages` instead; migration is an open blueprint question, not yet acted on |
| `k54-ai/v1` | **Custom K54 plugin** (not third-party) | AI Assistant chat backend (`chat`, `create-group`, `test`) | Unknown — not yet tested | **None** — `ai_page.dart` is a UI shell unaware this API exists. Dedicated audit scheduled after the 7 core features per current priority order. |
| `bb-social-login/v1` | BuddyBoss (native social-login bridge) | Social login incl. Microsoft OAuth redirect | OAuth-based | **None** — app's social login buttons are decorative |
| `nextend-social-login/v1` | Nextend Social Login | Social login (Facebook/Google/X) | OAuth-based | **None** — same as above |
| `learnpress/v1` | LearnPress | LMS: courses, quizzes, lessons, sections | **Own system** — has its own `token`/`token/register`/`token/validate` routes, separate from site JWT (untested whether JWT also works here) | **None** |
| `tutor/v1` | Tutor LMS | LMS: courses, quizzes, topics, course ratings/announcements, `ecommerce-webhook` | Unknown — not yet tested, likely standard WP REST | **None** |
| `wpstream/v1` | WPStream | Live streaming / VOD / pay-per-view, incl. `playback-session-verify` | Unknown | **None** — feature not in app at all |
| `tec/v1`, `tec/v2/onboarding`, `tribe/events`, `tribe/event-aggregator`, `tribe/views` | The Events Calendar | Events, organizers, venues (two coexisting API generations) | Standard WP (public GET likely, admin-gated writes) | **None** — feature not in app at all |
| `wp/v2` | WordPress Core | Posts, pages, media, users, comments, core taxonomies/types | Standard WP (JWT should work via `determine_current_user`, not individually tested here) | **None directly** — BuddyBoss layers on top of some core registrations, but the app never calls `wp/v2` itself |
| `google-site-kit/v1` | Google Site Kit | Analytics | N/A | None — not app-relevant |
| `hostinger-easy-onboarding/v1`, `hostinger-reach/v1`, `hostinger-tools-plugin/v1`, `hostinger-ai-assistant/v1`, `hostinger-amplitude/v1` | Various Hostinger-bundled plugins | Hosting-provider tools, onboarding, analytics, and Hostinger's own AI widget (confirmed unrelated to K54/Better Messages — see `messaging-better-messages.md`) | N/A | None — not app-relevant |
| `code-snippets/v1` | Code Snippets | Admin utility (custom PHP snippets) | N/A | None |
| `elementor-one/v1` | Elementor | Page builder | N/A | None |
| `image-optimizer/v1` | Image Optimizer | Admin utility | N/A | None |
| `litespeed/v1`, `litespeed/v3` | LiteSpeed Cache | Caching | N/A | None |
| `wp-site-health/v1` | WordPress Core | Site health diagnostics | N/A | None |
| `wp-abilities/v1` | WordPress Core | Core "abilities" API (newer WP feature) | N/A | None |
| `spl-weather/v2` | Location Weather | Weather widget | N/A | None |
| `live-news/v1` | Live News | News ticker widget | N/A | None |
| `batch/v1`, `oembed/1.0` | WordPress Core | Batch requests, oEmbed | N/A | None |
| `mcp`, `mcp/mcp-adapter-default-server` | Unknown — possibly an AI-tooling integration (Model Context Protocol) bundled with one of the Hostinger AI plugins | Unclear purpose, not investigated | Unknown | None — flagged for awareness only, not pursued unless it becomes relevant |

## What this tells us at a glance

- **The app's real, load-bearing dependencies today are exactly two plugins:** JWT Authentication (auth) and BuddyBoss Platform (everything else it currently does). Every other plugin on the site is either unused by the app or represents a documented, not-yet-acted-on opportunity (Better Messages) or gap (LearnPress/Tutor, WPStream, Events Calendar, both social-login systems).
- **BuddyBoss itself is only partially used** — of ~133 routes, the app touches a handful (messages, xprofile, members, activity/favorite, signup). Groups, Friends, Notifications, Forums, Video, Polls are all real, confirmed-to-exist BuddyBoss features the app doesn't call at all yet — directly relevant to the next several audits in the current priority order.
- **Two LMS plugins and two social-login systems being simultaneously active are both unresolved product questions**, not just technical ones — worth a decision from whoever owns the website, not something to infer from route counts alone.
