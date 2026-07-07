# WordPress REST Route Index (full platform)

Source: `GET https://k54global.com/wp-json/` — a public, **unauthenticated** WordPress REST API discovery endpoint listing every registered route across every plugin. Fetched directly via curl (not summarized), parsed programmatically. 842 total routes. Raw file saved as `.claude/wpjson_index.json` for future reference/re-parsing.

This is a durable, zero-cost reference — no capture or auth needed to reproduce it, just re-fetch that URL. Use it to check "does an endpoint exist" before assuming it doesn't, across any feature area.

## Namespace summary (route counts)

| Namespace | Routes | Relevance |
|---|---|---|
| `better-messages/v1` | 233 | Messaging — most (117) are `admin/*` (site-admin config, not app-relevant). See breakdown below. |
| `wp/v2` | 176 | WordPress core (posts, pages, media, users, etc.) |
| `buddyboss/v1` | 133 | Core social platform — activity, groups, members, xprofile, messages, forums, and more. See breakdown below. |
| `google-site-kit/v1` | 54 | Analytics, not app-relevant |
| `hostinger-easy-onboarding/v1` | 29 | Hosting-provider onboarding, not app-relevant |
| `learnpress/v1` | 29 | LMS — has its own token auth system, see below |
| `code-snippets/v1` | 17 | Admin utility, not app-relevant |
| `elementor-one/v1` | 16 | Page builder, not app-relevant |
| `image-optimizer/v1` | 16 | Admin utility, not app-relevant |
| `tribe/events` (v1) | 15 | Events Calendar (legacy API generation) |
| `tutor/v1` | 14 | LMS — the other candidate for Courses |
| `hostinger-reach/v1` | 12 | Hosting-provider tool, not app-relevant |
| `jwt-auth/v1` | 11 | The app's own auth mechanism |
| `litespeed/v1` + `/v3` | 15 | Caching, not app-relevant |
| `tec/v1` | 8 | Events Calendar (newer API generation) |
| `wp-site-health/v1` | 8 | Admin utility |
| `hostinger-ai-assistant/v1` | 6 | Hostinger's own widget — confirmed unrelated noise (see `messaging-better-messages.md`) |
| `wp-abilities/v1` | 6 | WP core, not app-relevant |
| `k54-ai/v1` | 4 | **Custom, K54-specific** — likely the AI Assistant page's real backend |
| `hostinger-tools-plugin/v1` | 4 | Not app-relevant |
| `spl-weather/v2` | 4 | Location Weather widget, not app-relevant |
| `tribe/event-aggregator` | 3 | Events Calendar sub-feature |
| `bb-social-login/v1` | 3 | A **second** social-login system, separate from Nextend — see Auth note below |
| `hostinger-amplitude/v1` | 3 | Analytics, not app-relevant |
| `live-news/v1` | 3 | News ticker widget, not app-relevant |
| `nextend-social-login/v1` | 2 | The social login plugin confirmed active earlier |
| `wpstream/v1` | 2 | Live Streaming/VOD — minimal public REST surface |
| `tribe/views` (v2) | 2 | Events Calendar sub-feature |
| `tec/v2/onboarding` | 2 | Events Calendar admin setup |
| `batch/v1`, `mcp`, `mcp/mcp-adapter-default-server`, `oembed/1.0` | 1 each | WP core / infra, not app-relevant |

## `better-messages/v1` breakdown (233 routes)

| Sub-resource | Count | Notes |
|---|---|---|
| `admin/*` | 117 | Site-admin configuration UI's own API — not relevant to a mobile client |
| `thread/*` | 40 | Per-thread actions — the ~11 we already captured are a subset of this |
| `bulkMessages/*` | 15 | Likely an admin broadcast/bulk-send tool |
| `ai/*` | 8 | **Confirmed real** — bots, translation, transcription, moderation (see correction above) |
| `app/*` | 5 | **Official mobile-app integration** — `login`, `savePushToken`, `getSettings`, `syncScripts` — needs investigation before finalizing the messaging blueprint |
| `reports/*` | 3 | Message/user reporting |
| `guests/*` | 2 | Possibly an anonymous/guest chat widget mode, likely unrelated to the authenticated app |
| `chat/*`, `userSettings/*`, `pushNotifications/*` | 2 each | `pushNotifications/save` + `/delete` confirm real push-token registration |
| Single-route: `blockUser`, `unblockUser`, `reactions`, `getUsers`, `sendTestEmail`, `unsubscribe`, `getChatRooms`, `getEmojiData`, `search`, `getFriends`, `getGroups`, `getCourses`, `getFavorited`, `ping`, `checkNew`, `openThreads`, `markAllRead`, `threads`, `suggestions`, `userSuggestions`, `getPrivateThread`, `lazyPool`, `publicProfiles`, `getUniqueConversation`, `threadsPicker`, `message`, `getAIBots`, `callStart`, `callCreate`, `joinCall`, `callStarted`, `callUsage`, `callMissed`, `offlineCall`, `groupCallStart`, `groupCallAdmin` | 1 each | Far more than the ~11 endpoints captured via HAR — `search`, `markAllRead`, `getFavorited`, `getUniqueConversation` (possibly server-side thread dedup — relevant to the app's own client-side dedup logic), `blockUser`/`unblockUser`, and the full calling lifecycle (`callStart`/`joinCall`/`callStarted`/`callUsage`/`offlineCall`/`groupCallStart`/`groupCallAdmin`) are all confirmed to exist but not yet exercised in any capture. |

**`getCourses` existing as a Better-Messages route** is a small, easy-to-miss cross-feature link — messaging apparently has some integration point with Courses, not yet understood.

## `buddyboss/v1/activity` breakdown (14 routes) — directly useful for the Activity Feed audit

```
GET,POST   /activity
GET,POST,PUT,PATCH,DELETE /activity/{id}
POST,PUT,PATCH  /activity/{id}/close-comments
GET,POST   /activity/{id}/comment
GET,POST,PUT,PATCH,DELETE /activity/{id}/comment/{comment_id}
POST,PUT,PATCH  /activity/{id}/favorite
POST,PUT,PATCH  /activity/{id}/notification
POST,PUT,PATCH  /activity/{id}/pin
POST       /activity/{id}/share
GET        /activity/details
POST       /activity/featured-image/upload
POST,PUT,PATCH,DELETE /activity/featured-image/upload/{id}
GET        /activity/link-preview
GET        /activity/sharing-settings
```
Full comment CRUD, pin, share, per-post notification toggle, featured-image upload, and link-preview are all confirmed to exist — none of these are implemented in the Flutter app today (only feed load + favorite are). Significant expansion of the known Activity Feed gap, confirmed without needing a capture.

## `buddyboss/v1/pusher` (3 routes) — a nuance on the earlier Pusher correction

```
POST,PUT,PATCH  /pusher/auth
GET             /pusher/data
POST,PUT,PATCH  /pusher/user-auth
```
The earlier correction ("typing indicators come from Better Messages, not BuddyBoss Pusher") was specifically about **messaging** and remains correct (confirmed via extensive live WS capture). But BuddyBoss Platform does have *some* Pusher integration, evidenced by these routes — `pusher/auth`/`pusher/user-auth` are classic Pusher private/presence-channel authorization endpoints. Most likely serves Activity Feed's own real-time updates, not messaging. Worth investigating specifically when Activity Feed is captured, not assumed either way.

## `bb-social-login/v1` (3 routes) — a second social-login system

```
GET  /bb-social-login/v1
POST /bb-social-login/v1/{provider}/get_user
GET  /bb-social-login/v1/microsoft/redirect_uri
```
Separate from the Nextend Social Login plugin confirmed active earlier (`nextend-social-login/v1`, 2 routes). Whether these are two independent systems or one bridges into the other is unconfirmed. Relevant to the Auth feature's social-login gap — there may be more than one provider path to reconcile, not just Nextend.

## LMS: LearnPress vs. Tutor LMS — a real, testable lead

`learnpress/v1` (29 routes: courses, quiz, users, **token** ×3, lessons, questions, course_category, sections, section-items) vs. `tutor/v1` (14 routes: courses, quizzes, topics, lessons, course-announcement, quiz-question-answer, quiz-attempt-details, author-information, course-rating, course-contents, ecommerce-webhook).

**LearnPress has its own dedicated authentication token system** (`token`, `token/register`, `token/validate`) — distinct from the site-wide JWT plugin. If LearnPress turns out to be the one actually used for Courses, the app likely needs a *separate* auth step for it, not an assumption that the existing JWT bearer token works there too — directly testable the same way Better Messages was (a curl call), recommended when Courses is audited. LearnPress's richer, more granular REST surface (course_category, sections, section-items) is a *lead*, not proof, that it's the more REST/headless-oriented of the two — Tutor's flatter surface plus an `ecommerce-webhook` route suggests it may lean more on WooCommerce-style purchase flows. Confirm via an actual Courses-page capture, don't decide from route counts alone.

## `wpstream/v1` (2 routes) — Live Streaming/VOD

```
GET /wpstream/v1
GET /wpstream/v1/playback-session-verify
```
Minimal public REST surface — `playback-session-verify` suggests a session/token-gated playback-access-control mechanism (relevant if pay-per-view content needs to be supported).

## Events Calendar — two API generations coexisting

`tec/v1` (events, organizers, venues, docs) is the newer generation; `tribe/events` (v1, 15 routes), `tribe/event-aggregator`, `tribe/views` (v2), `tec/v2/onboarding` are older/parallel. Both appear active — worth checking which one the live site's frontend actually calls before building against either.
