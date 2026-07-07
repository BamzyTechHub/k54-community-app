# Gap Analysis & Prioritized Implementation Roadmap

Final Phase 1 deliverable. Synthesizes all 9 audited features (`messaging-*.md`, `activity-feed.md`, `members.md`, `profile-xprofile.md`, `friends.md`, `groups.md`, `notifications.md`, `courses.md`, `ai-assistant.md`) into: what's broken independent of parity, what's missing, what's cheap to wire versus expensive to build, and a sequencing recommendation for Phase 2. This is still documentation — nothing here is implemented.

## Executive summary

| # | Feature | Flutter Coverage | Confirmed Bugs | Missing Features | Decorative UI | Evidence Confidence |
|---|---------|-------------------|------------------|---------------------|-----------------|------------------------|
| 1 | Messaging | 25% | 1 (open) | 14 | 0 | ~67% |
| 2 | Activity Feed | 20% | 2 | 11 | 12 | ~71% |
| 3 | Members Directory | 0% | 0 | 9 | 8 | ~63% |
| 4 | Profile / XProfile | 20% | 2 | 6 | 1-2 | ~70% |
| 5 | Friends | 0% | 0 | 7 | 7 | ~61% |
| 6 | Groups | 0% | 0 | 14 | 11 | ~65% |
| 7 | Notifications | 29% | 0 | 4 | 0 | ~71% |
| 8 | Courses | 0% | 0 | 10 | 1 | ~50% |
| 9 | K54 AI Assistant | 0% | 1 (backend) | 7 | 3 | ~90% |

**Average Flutter Coverage: ~10% across the 7 priority-ordered features, ~12% including Messaging.** Four features are at a confirmed, literal 0%. Full definitions and per-feature capability lists are in `parity-scorecard.md` and each feature's own file — nothing here is asserted without a shown basis.

## ⚠️ Urgent, outside the normal roadmap: K54 AI Assistant backend security

PHP source for `k54-ai/v1` (obtained 2026-07-08) shows both `/chat` and `/create-group` are **completely unauthenticated in production** — every route's `permission_callback` unconditionally returns true, and an explicit `rest_authentication_errors` filter forces WordPress's own REST auth check to pass for the entire namespace regardless of credentials. There is no rate limiting anywhere in either handler. Practical effect: any anonymous internet visitor can currently make unlimited calls to OpenAI through K54's own API key (a direct cost-drain vector) and create real, live BuddyBoss groups on the community site attributed to no one (`creator_id = 0`).

**This is categorically different from everything else in this roadmap** — the rest of this document is about closing feature-parity gaps, which can reasonably wait for a planned Phase 2. An active, exploitable, unauthenticated write endpoint on a live production site with real users is not that kind of problem. Recommend confirming with whoever owns deployment whether this code is currently live, independent of and prior to the sequencing below. Full technical detail, including 3 more security/maintainability findings on the same file, is in `ai-assistant.md`'s PHP Backend Code Review section.

## Confirmed Bugs — fix independent of everything else below

These aren't parity gaps, they're defects in code that's supposed to already work. The first five are cheap, isolated Flutter-side fixes that don't depend on any new backend integration:

| # | Bug | Location | Impact |
|---|---|---|---|
| 1 | `InboxController` disposal crash | `lib/messaging/controllers/inbox_controller.dart` | Same unguarded `notifyListeners()`-after-dispose pattern `ChatController` had (fixed this project) — still open |
| 2 | Timeline like-toggle full reload | `lib/Profile/timeline_page.dart` | Liking a post triggers a full feed refetch (loading spinner, lost scroll position) instead of a targeted update — contradicts `K54_PROJECT_HANDOFF.md`'s claim this was already fixed |
| 3 | Image silently dropped on publish | `lib/posts/create_post_page.dart` | Picked images preview correctly but are never sent to the server — publish "succeeds" without the image |
| 4 | Onboarding silent failure | `lib/profile_setup.dart` | Still the pre-fix Firebase version — `auth.currentUser` is always null, save silently no-ops, no error shown. Reachable from `face_id_verified.dart`/`touch_id_verified.dart`, not dead code. |
| 5 | Edit Profile fake success | `lib/Profile/edit_profile_page.dart` | Writes to a disconnected static in-memory class, shows "Profile updated successfully," persists nothing — the worst of the five since it actively misleads the user |
| 6 | AI backend always returns HTTP 200, even on failure | K54 AI Assistant's PHP backend (not in this repo — see `ai-assistant.md`) | Every error path (`is_wp_error`, empty reply, missing BuddyBoss Groups) returns 200 with a text message embedded in the JSON body — a client can only detect failure by string-matching known phrases. Listed here for completeness since it directly shapes the Flutter blueprint's error handling, but it's a server-side fix, not something this repo's fixes can address. |

**Recommendation: fix #1-5 before or alongside starting any Phase 2 feature work.** None require new API integration — #1, #2, #4 are logic fixes; #3 needs the already-picked file attached to the existing `createPost` call; #5 needs `EditProfilePage` pointed at the real profile-update endpoint (blocked on real field IDs, see below). **#6 is out of scope for this repo** (it's WordPress-side PHP) but is tracked here since the Flutter AI Assistant blueprint has to be built around it regardless — see the urgent security note above for the same file's more serious findings.

## Documentation Drift — treat prior docs with calibrated skepticism going forward

| # | Claim | Source | Contradicted by |
|---|---|---|---|
| 1 | Better Messages uses `admin-ajax.php?action=checkNew` | `K54_PROJECT_HANDOFF.md` | HAR evidence: it's a real REST route, `/wp-json/better-messages/v1/checkNew` |
| 2 | "No evidence for AI conversations" in Better Messages | This audit's own earlier session | Full REST route index: `better-messages/v1/ai/*` (8 routes) is real — self-correction, recorded rather than silently fixed |
| 3 | Onboarding rewritten to remove Firebase, call `BuddyBossService().updateProfileFields()` | `K54_PROJECT_HANDOFF.md`, `CLAUDE.md` | Current code: neither the rewrite nor `updateProfileFields()`/`XProfileFields` exist anywhere in the codebase (confirmed via grep) |
| 4 | AI Assistant "may not be a website-parity feature... needs requirements gathering" | Original `feature-inventory.md`, pre-audit | A real, custom backend (`k54-ai/v1`) already exists — this was an integration gap, not a requirements gap |

**Implication:** `K54_PROJECT_HANDOFF.md` has now been directly contradicted twice (items 1 and 3) by evidence gathered in this audit, both times on claims of "this was already fixed." Its other "fixed this session" claims should be re-verified against current code before being trusted, not assumed accurate by default.

## Cross-cutting themes

- **The website's own UI runs on legacy `admin-ajax.php` actions, not the REST API a mobile client needs** — confirmed across Messaging, Members, Groups, and Activity Feed independently. This means capturing the website's Network tab documents *the website's* contract, not the app's — the app's own traffic (or direct REST testing) remains the source of truth for what the app should call. Established early, held up in every subsequent feature.
- **Several "missing" features already have working plumbing elsewhere in the codebase — they just aren't connected.** Members Directory's Message button could call the already-working `findOrCreateThreadWith` today. Notifications' entry icon could use the already-working `UnreadBadge`. These are wiring tasks, not new development — flagged individually in `architecture-recommendations.md`, worth doing before any new backend integration since they're nearly free.
- **Decorative UI is heavily concentrated in the social-graph features** (Members, Friends, Groups, Courses average ~0% coverage, 8-11 decorative elements each) versus content/utility features (Messaging, Activity Feed, Profile, Notifications, which all have at least partial real wiring). This isn't a comment on difficulty — it's simply where build effort hasn't reached yet, confirmed by direct code inspection rather than assumed.
- **A recurring, systemic bug pattern:** profile links built from a raw numeric `user_id` (`post_model.dart`) instead of the confirmed real slug format (`/members/{slug}/`) — found in two places, likely more given the pattern. Worth a targeted sweep rather than fixing opportunistically.
- **Firebase/Firestore remnants are more load-bearing than previously believed.** `CLAUDE.md` already flagged deciding Firebase's fate as a cleanup item; this audit found `profile_setup.dart` (a *reachable* screen, not dead code) still fully depends on it, with a real user-facing failure mode as a result — raises the priority of that decision.
- **The two-surfaces ambiguities (Groups: `screen/` vs `communication/`) remain unresolved product decisions**, not code problems — confirmed this audit that the two Groups surfaces show genuinely different mock content, reinforcing they need a decision, not a merge-by-default.

## Missing-feature volume by area (for roadmap sizing, not a commitment)

- **Activity Feed (11):** comments, pin, share, close-comments, per-post notification toggle, real featured-image upload, link-preview, real-time via pusher, pagination, edit post, delete post.
- **Groups (14):** essentially the entire feature, plus the forums/moderation sub-system (17 additional confirmed routes with zero UI anywhere).
- **Messaging (14):** reactions, translations, favorites, pin/mute/erase, calling (1:1 + group), block/unblock, AI-in-chat, voice transcription, search, read receipts, presence, push notifications.
- **Courses (10):** the entire feature — browsing, enrollment, lessons, quizzes, ratings.
- **Members (9) / Friends (7) / Notifications (4) / AI Assistant (7, provisional):** see each feature's own file for the itemized list.

## Prioritized implementation roadmap (Phase 2 sequencing recommendation)

Still planning, not implementation — sequencing only, to be revisited once the user decides how to proceed.

### Stage 0 — Fix independent of everything else
The 5 Confirmed Bugs above. No new API integration required, all isolated, all improve currently-shipping behavior.

### Stage 1 — Wire already-working plumbing (near-zero net-new code)
- Members Directory's Message button → `findOrCreateThreadWith`.
- Notifications entry icon → `UnreadBadge`.
- Chat send → optimistic pattern (confirmed to match the website's own behavior, not just a nicety).

### Stage 2 — Build out features with the most existing evidence and partial wiring already in place
Ordered by a combination of "how much groundwork already exists" and "how contained the remaining work is":
1. **Activity Feed** — feed load, likes, and create-post already work; comments/pin/share/media are additive, not a rewrite, and have full confirmed endpoint schemas to build against.
2. **Profile/XProfile** — viewing already works; blocked specifically on real field IDs (`GET /buddyboss/v1/xprofile/groups?fetch_fields=1`, directly testable) before real editing can be built at all.
3. **Notifications** — the UI/interaction layer is already correct (unusual among the 0%-adjacent features); this is close to pure data-wiring once a usable REST response is confirmed.

### Stage 3 — Build out features starting from zero, well-scoped now
4. **Members Directory** — 0% today, but fully scoped: 12 confirmed routes, clear capability list.
5. **Friends** — smallest surface (2 routes), simplest to fully build.
6. **Groups** — largest remaining scope (33 routes incl. forums); also needs the two-surfaces product decision resolved first or alongside.
7. **Courses** — blocked on confirming LearnPress vs. Tutor LMS against the live site, and (if LearnPress) its separate auth test — both cheap, concrete next steps, not open-ended research.

### Stage 4 — Contingent on product/vendor decisions, not just engineering effort
- **Messaging Stage B/C** (adopting Better Messages REST for reactions/calls/etc., and separately, WebSocket real-time) — technically unblocked (JWT confirmed compatible) but a large surface; WebSocket specifically still needs a vendor conversation about the third-party dependency.
- **K54 AI Assistant** — no longer blocked on evidence (PHP source obtained, full blueprint exists in `ai-assistant.md`); sequencing here is really about whether to build against the current backend as-is or wait for the security issue above to be addressed first, which is a product/risk decision, not an engineering one.
- **Social login** (Nextend + the newly-found `bb-social-login`) — real, confirmed website feature with zero app equivalent; needs a priority decision, not more investigation.
- **Groups two-surfaces reconciliation** — product decision, referenced in Stage 3 but may need resolving independent of the build itself.

### Explicitly out of this roadmap
Marketplace (needs requirements gathering — unclear if it's even the Printify integration), Live Streaming/VOD and Events (newly discovered, not in original scope — see `future-discoveries.md`), and platform configuration documentation (roles/capabilities, plugin settings — needs WP Admin screenshots, still pending).

## What Phase 1 produced, for reference

`plugin-inventory.md`, `rest-route-index.md`, `dependency-map.md` (platform-wide reference material) · `feature-inventory.md` (dashboard) · `parity-scorecard.md` (this file's scoring source) · `architecture-recommendations.md` (Phase 2 reuse backlog) · `implementation-blueprint.md` (Messaging's detailed technical plan — the template for future features' blueprints) · nine per-feature audit files · this file.
