# K54 API Audit — Phase 1: Website Reverse-Engineering

## Objective

Three-way parity: the **website** (`k54global.com`) is the source of truth for functionality, workflows, and backend behavior; the **Figma design** (K54 Mobile App file) is the source of truth for UI/UX, layout, navigation, and components; the **Flutter app** must ultimately match both. We do not assume any two of these three are already equivalent — every claim in this audit must be confirmed from real evidence (a captured Network request for behavior, an exported Figma frame or Dev Mode spec for design), never from general documentation or assumption. Where the three disagree, that's a parity gap to record, not something to silently resolve in favor of whichever one seems more "correct."

No production code changes happen during this phase. Three deliverables grow alongside the audit, each with a distinct job — don't let content blur across them:
- `gap-analysis.md` — *what* differs (website vs. Figma vs. app), the problem statement.
- `architecture-recommendations.md` — reuse/architecture ideas noticed opportunistically while documenting, not necessarily gap-driven.
- `implementation-blueprint.md` — *how* to actually close each gap once Phase 2 starts: which API to target, concrete services/models/controllers, WebSocket needs, compatibility risks, and a staged parity approach. Added per-feature once that feature has enough confirmed evidence to plan against. Still planning, not code, until explicitly asked to implement.

### Figma access constraint

There is no tool available in this environment that can read Figma design-canvas content — WebFetch only returns Figma's app shell (the canvas is WebGL/JS-rendered, not server-rendered HTML, so this is true even for fully public files), and no Figma API/MCP integration is configured. Design evidence has to come in as: (a) exported frame images (PNG/JPG, via Figma's Export panel) placed somewhere readable on disk or pasted inline, or (b) Dev Mode inspect-panel text (exact spacing/color/type values) pasted as plain text. Screenshots establish layout/visual comparison; Dev Mode text is needed for exact values.

## Methodology

1. Capture via browser DevTools Network tab, "Preserve log" on, exported as **HAR with response content** (not just headers) — right-click the Network panel → "Save all as HAR with content".
2. One HAR per feature area (see file list below), captured as a continuous session covering the full flow for that area (initial load → interactions → pagination/infinite scroll → any polling/WS activity over ~15-20s).
3. For SPA-routed sections (confirmed for `/messenger/`), "Preserve log" must be enabled *before* the hash-route change, since client-side navigation doesn't produce a new "Doc" entry in Network.
4. Every documented endpoint must cite which capture it came from (filename + timestamp) so it can be re-verified later if the site changes.
5. Every finding carries an explicit confidence tag (formalized 2026-07-07 — supersedes the old prose-only "Confirmed/Inferred/Unknown" labels with a consistent, skimmable format; the underlying meaning is the same, just sharper):

   - **✅ Confirmed** — directly observed. `Source:` one or more of HAR capture / direct REST call (curl or captured live traffic) / Flutter source code / direct website-behavior observation.
   - **🟡 High confidence** — a real artifact exists (route confirmed, code confirmed working) but the *specific claim* wasn't independently observed. `Source:` what is confirmed. `Missing:` exactly what would be needed to upgrade to ✅ (e.g. "actual response body," "a second role's behavior").
   - **🔴 Hypothesis** — plausible but unverified, or verification blocked on an artifact-encoding issue, an inference from a pattern, or a route's mere existence with no behavior observed at all. `Needs:` the specific evidence that would resolve it (HAR, JWT test, plugin config screenshot, etc.).

   Never silently upgrade a 🟡/🔴 finding to ✅ without the evidence that justifies it actually landing.

6. **Discrepancy classification** — whenever documentation, website behavior, Flutter code, HAR evidence, REST routes, or Figma disagree with each other, classify the discrepancy explicitly as one of:
   - **Confirmed Bug** — the app does something wrong relative to its own intent (crashes, silently drops data, etc.), independent of website parity.
   - **Missing Feature** — the website/Figma has real behavior the app doesn't implement at all.
   - **UI-only Placeholder** — a control exists in the app's UI with no backend effect (decorative buttons, TODO handlers).
   - **Documentation Drift** — a prior document (including this audit's own earlier entries, or `K54_PROJECT_HANDOFF.md`) claims something the current evidence contradicts.
   - **Technical Debt** — works today, but the implementation has a known fragility or inefficiency.
   - **Architectural Opportunity** — not a defect, a chance to consolidate/simplify (belongs in `architecture-recommendations.md`, cross-referenced here).

   **Never silently resolve a conflict.** Record both the previous assumption/claim and the newly confirmed evidence side by side, with the classification — don't just quietly overwrite what was written before.

## Parity Scorecard

Every completed feature audit ends with a scorecard. Definitions (fixed, so scores are comparable across features):

- **Website Coverage** — always shown as the parity *baseline* (the website's confirmed behavior is the 100% target Flutter is measured against), **not** a claim that we've documented 100% of the website's actual behavior — that thoroughness is tracked separately by **Evidence Confidence** below. Don't conflate the two.
- **Flutter Coverage** — the percentage of the website's *confirmed* capabilities for this feature that the Flutter app actually implements (computed as implemented-capabilities ÷ confirmed-capabilities, with the capability list shown so the number is auditable, not asserted).
- **Parity** — same as Flutter Coverage, given the Website=100% baseline convention above; kept as a separate line because future scoring refinements (e.g. weighting by user-facing importance) may make them diverge.
- **Confirmed Bugs / Missing Features / Decorative UI** — raw counts, each linking back to the Discrepancy Log entries that justify them.
- **API Coverage** — endpoints the app calls ÷ endpoints confirmed to exist for this feature (distinguish from Flutter Coverage, which is about capabilities, not raw endpoint counts — a feature can have high API coverage but low capability coverage if the called endpoints are the simple ones).
- **Evidence Confidence** — proportion of this feature's findings tagged ✅ vs. 🟡/🔴 — the audit-thoroughness metric.

Running summary across all features: `parity-scorecard.md` — updated after each feature audit completes.

### Discrepancy Log and Parity Scorecard in the per-area template

Both are now required sections in every feature file (added to the template below).

## Documenting functional behavior, not just traffic

Network capture alone only shows *that* a request happened — not the business rules, validation, permission-conditional UI, or state transitions behind it. Those require direct observation. Every capture session should be paired with a short behavioral narrative: what was clicked, what appeared/disappeared, anything tried that produced an unusual result (disabled controls, hidden menu items, validation messages, empty/error/offline states deliberately triggered). Without this narrative, a HAR only documents the network layer, not the feature.

Role/permission variations require test accounts across roles. Where only one role is available, document that role's confirmed behavior and mark other roles explicitly as **untested** — never infer what a different role would see.

### Per-area file template

Every `*.md` feature file should follow this structure so coverage stays consistent:

```
# Feature: <name>

## Status
Website / Flutter / Figma — one line each, Confirmed/Partial/Not yet captured.

## Network Behavior
Endpoints, HTTP methods, headers, auth, request/response schemas, pagination,
polling/WebSocket/SSE, error responses, rate limits. Cite the capture (filename
+ timestamp) each finding came from.

## Functional Behavior
- Business rules
- Validation rules
- Feature flags / conditional behavior
- UI interactions & transitions
- State machine (idle / loading / success / error / empty / offline / etc.)
- Client-side logic not obvious from the API alone
- Server-side assumptions inferred from responses
- Edge cases / unusual behavior observed

## Role / Account-Status Variations
One subsection per role/status actually tested. Anything not tested is listed
as untested, not assumed identical to a tested role.

## Undocumented / Plugin-Specific Behavior
Anything traced beyond black-box treatment — note how far it was traced and
by what method (e.g. "traced via response header X", "inferred from timing
of two sequential requests", "confirmed by disabling network and observing Y").

## Open Questions

## Discrepancy Log
Every conflict between documentation/website/Flutter/HAR/REST/Figma found while
auditing this feature, classified as: Confirmed Bug / Missing Feature /
UI-only Placeholder / Documentation Drift / Technical Debt / Architectural
Opportunity. Show the previous assumption and the new evidence side by side —
never just silently overwrite.

## Parity Scorecard
Website Coverage / Flutter Coverage / Parity / Confirmed Bugs / Missing
Features / Decorative UI / API Coverage / Evidence Confidence — per the
fixed definitions in README.md. Show the capability list the percentages
were computed from, not just the numbers.
```

Where the Flutter app's *current* behavior for a given dimension (state machine, validation, dedup logic, etc.) is derivable straight from its own source code, that doesn't need a capture — it's documented now, from the repo, same as anything else already confirmed in this project.

## Known system split (established prior to this audit, now confirmed platform-wide)

`k54global.com` runs (at least) three parallel systems, not two — this was first identified for messaging but the first real HAR (2026-07-07) shows it generalizes to the whole website:

- **BuddyBoss REST API** (`/wp-json/buddyboss/v1/...`, `/wp-json/better-messages/v1/...`) — nonce via `X-WP-Nonce` **header**. This is what the Flutter app uses (via JWT bearer instead of cookie+nonce) and must continue to use. Confirmed this also covers Better Messages' own real-time-check endpoint (`checkNew`) — it has a proper REST route, not a pure AJAX action as previously assumed (correction — see `messaging-better-messages.md`).
- **Legacy `admin-ajax.php` actions** — the website's own theme/UI (bp-nouveau) drives most in-page interactions this way: confirmed for messaging (was wrongly attributed to this in the original handoff doc, actually uses REST — see above), and now separately confirmed for **Members** (`action=members_filter`), **Groups** (`action=groups_filter`, `action=groups_join_group`), and **Activity** (`action=heartbeat`, carrying BuddyPress-specific `bp_activity_last_recorded`/`bp_heartbeat` params for the live "new activity" banner). Auth here is a nonce passed as a **POST body field** (name varies per action/plugin: `nonce`, `_nonce`, `_wpnonce`), verified server-side via `check_ajax_referer` — a different mechanism from the REST header nonce.
- **Third-party plugin systems bolted alongside**, e.g. Better Messages' WebSocket add-on (real-time transport, not yet confirmed live in practice) and its Voice Messages add-on.

**Generalized implication for every remaining feature area:** expect the website's own Network traffic to show `admin-ajax.php` actions, not the REST API a mobile client would use. Capturing the website's UI documents *the website's own legacy AJAX contract* — useful for understanding business rules/behavior, but not a stand-in for the REST endpoints the app needs. Keep treating "the app's own REST traffic" as the source of truth for the REST contract in every feature file, exactly as established for messaging.

Do not conflate legacy-AJAX findings with REST findings in any per-area file — file them in clearly separate subsections (see template above), the same way messaging's two files stay separate.

## File index

- `plugin-inventory.md` — full plugin list from WP Admin, with relevance notes and open questions raised by it (e.g. two LMS plugins active, social login gap, Members role-management plugin).
- `rest-route-index.md` — the complete platform-wide REST route list (842 routes, all namespaces), fetched directly from the public unauthenticated `GET /wp-json/` discovery endpoint — zero-cost, no capture needed, reusable reference for "does an endpoint exist" across every feature area. Raw JSON cached at `.claude/wpjson_index.json`.
- `dependency-map.md` — every REST namespace mapped to its owning plugin, purpose, auth method, and current Flutter usage (Uses/Partial/None). Answers "which plugin does this feature ultimately depend on" at a glance.
- `ai-assistant.md` — dedicated audit of K54's custom AI feature. **Updated 2026-07-08 with actual PHP source** — Evidence Confidence jumped from ~21% to ~90%. Full request/response lifecycle, OpenAI integration, and a classified PHP code review are documented. ⚠️ Surfaces an unauthenticated-production-endpoint security finding — see `gap-analysis.md`'s urgent section.
- `future-discoveries.md` — holding pen for peripheral leads found during the core audit (Better Messages' mobile app integration, WPStream, Events Calendar, the second social-login system, etc.) that are deliberately not expanding the current 7-feature priority order. K54 AI Assistant is explicitly NOT here — it's a first-class feature in `feature-inventory.md` with its own dedicated audit scheduled after the core 7.
- `parity-scorecard.md` — running Website/Flutter/Parity/Bugs/Missing/Decorative-UI/API-Coverage/Evidence-Confidence table, one row per completed feature. Computed from each feature file's own scorecard section, not asserted independently.
- `feature-inventory.md` — **master dashboard, single source of truth.** One row per feature across the whole platform (not just messaging), tracking website/Flutter/Figma status, APIs discovered, HAR/schema-documented flags, plugin dependencies, parity gaps, and priority side by side. Update this every time a HAR or Figma export is analyzed. Deep evidence and documentation stays in the per-area files below — this table should never accumulate detail that belongs there instead.
- `messaging-better-messages.md` — website's `/messenger/` SPA: routing, request sequence, polling/WS/SSE, typing indicators, read receipts, attachments, pagination.
- `messaging-buddyboss-rest.md` — the REST endpoints the Flutter app uses, built from the app's own confirmed traffic (not the website's).
- `activity-feed.md` — created, substantially complete from existing evidence (code + REST index + prior HAR). Genuine remaining gap: raw response schema for `GET /activity` (currently inferred from working code, not independently captured) and `pusher/*` investigation.
- `groups.md` — created, fully audited from existing evidence. 0% Flutter coverage confirmed across both surfaces; forums/moderation entirely unaddressed.
- `members.md` — created, fully audited from existing evidence (code + HAR1 + REST index). 0% Flutter coverage confirmed — no API calls, no navigation.
- `profile-xprofile.md` — created, fully audited from existing evidence. **Major finding: the handoff doc's claimed onboarding fix isn't present in the current code** (Documentation Drift), plus a new, previously-undocumented fake-success bug in Edit Profile.
- `notifications.md` — fully audited. Website-side mechanism confirmed (WP Heartbeat-delivered HTML + full REST surface); app-side has zero data wiring but, notably, its dummy interactions (mark-read etc.) genuinely work locally — the first feature with 0 Decorative UI.
- `friends.md` — created, fully audited from existing evidence. 0% Flutter coverage confirmed — even less built than Members Directory, no UI presence at all for requests/accept/reject.
- `courses.md` — fully audited, closes out the core 7. 0% coverage confirmed. LearnPress-vs-Tutor evidence substantially upgraded (full route lists show LearnPress owns the entire course-taking write lifecycle, Tutor is read-only).
- `gap-analysis.md` — **final Phase 1 deliverable, complete.** Synthesizes all 9 audited features: executive summary, cross-feature Confirmed Bugs list (5, all cheap/independent), Documentation Drift log, cross-cutting themes, and a staged Phase 2 sequencing recommendation. Still planning, nothing implemented.
- `architecture-recommendations.md` — reusable API/service opportunities and Flutter architecture improvements noticed during the audit, kept separate from parity gaps since these are optimizations, not correctness issues. Phase 2 backlog only — nothing here gets implemented during Phase 1.
- `implementation-blueprint.md` — the concrete Phase 2 plan per feature, following a fixed template (endpoints, auth, request sequence, response schema, models/repository/service changes, state management, real-time/WebSocket flow, pagination, error handling, optimistic updates, loading states, retry behavior, media upload workflow, compatibility risks, staged parity approach). Grows as each feature is audited; fully populated for Messaging.

## Capture log

| Date | Source | Area | Method | Notes |
|------|--------|------|--------|-------|
| 2026-07-07 | k54global.com/ (public homepage, unauthenticated) | General plugin/asset discovery | WebFetch | Confirmed: BuddyBoss Platform, bp-nouveau template, BuddyBoss Sharing, `bp-better-messages` referenced in asset paths (cross-confirms earlier finding independently). New: emoji rendering via Twemoji (`cdn.jsdelivr.net`), not a custom API. No LMS plugin signal — needs an authenticated Courses capture. |
| 2026-07-07 | WP Admin → Plugins (screenshot) | Full plugin inventory | Manual screenshot | See `plugin-inventory.md`. Confirms two LMS plugins active (LearnPress + Tutor LMS), Better Messages WebSocket + Voice Messages add-ons, Nextend Social Login (confirmed app parity gap), Members role-management plugin, WpStream + Events Calendar (untracked feature areas). |
| 2026-07-07 | `.claude/k54global.com.har` | Messenger (partial — no conversation opened), Members filter, Groups filter/join, Activity heartbeat | Browser HAR export | **Response bodies missing — exported without "with content," needs re-capture.** Confirmed: Better Messages' `checkNew` is a real REST route (`/wp-json/better-messages/v1/checkNew`), not admin-ajax as the original handoff doc claimed (correction). Confirmed legacy-AJAX pattern generalizes to Members/Groups/Activity, not just messaging. No WebSocket handshake captured — open question. See `messaging-better-messages.md`. |
| 2026-07-07 | `.claude/k54global.com HAR2.har` | Heartbeat (notifications/presence/unread messages) | Browser HAR export (3 entries, small but has real content this time) | Full `heartbeat` response body captured — confirms notification delivery mechanism (HTML fragments via Heartbeat, not a dedicated endpoint), presence feature shape, `/messenger/?thread_id={id}` deep-link format (corroborates/refines the hash-route form mentioned earlier), and member profile URLs use a slug not a numeric ID. See `notifications.md` and updates to `messaging-better-messages.md`. |
| 2026-07-07 | `.claude/k54global.com3` | Full Better Messages walkthrough: conversation open, send, file upload, audio call, pin/unpin, erase, live WebSocket | Browser HAR export (770 entries, 353 with content) | **Major capture.** Live WebSocket confirmed (`wss://cloud.better-messages.com`, Engine.IO/Socket.IO, full event protocol documented). Full REST endpoint inventory confirmed (`checkNew`, `threads`, `thread/{id}`, `/send`, `/upload`, `/makePinned`, `/erase`, `callCreate`, `callMissed`, `getFriends`, `getGroups`). Confirms reactions, translations, per-message favorites, calling, and a rich permission/friend/block model — none currently in the app. Confirms optimistic client-side send pattern. Raises an open strategic question: should the app target this API instead of BuddyBoss's (blocked on unconfirmed JWT-auth compatibility). See `messaging-better-messages.md` (substantially expanded) and `architecture-recommendations.md`. |
| 2026-07-07 | curl (outside browser) | JWT-bearer-only auth test against Better Messages REST | Manual curl request/response, user-run, 2 rounds | **Resolved.** Round 1: GET confirmed working JWT-only (`getFriends`, 200 with full data); POST inconclusive (`checkNew` hit a PowerShell JSON-quoting artifact, `400 rest_invalid_json`). Round 2 (retest with a file-based raw JSON body): **POST also confirmed working JWT-only** (`checkNew`, 200 with full envelope). Both GET and POST now confirmed JWT-bearer-only compatible, no cookie/nonce. Messaging's core architectural risk is resolved; WebSocket/real-time adoption remains a separate open decision. See `messaging-better-messages.md` and `implementation-blueprint.md` (substantially expanded with a full per-feature template). |
| 2026-07-07 | Existing Flutter code (`buddyboss_service.dart`, `post_model.dart`, `post_card.dart`, `timeline_page.dart`, `create_post_page.dart`, `home_page.dart`) | Activity Feed — mined from code, no new capture | Direct code reading | **Correction:** `K54_PROJECT_HANDOFF.md`'s claimed like-toggle fix is not present in the current code — the full-reload regression is real and confirmed. New confirmed bug: picked images are silently dropped on publish, never sent to the server. ~7 composer controls confirmed fully decorative. Full writeup in new `activity-feed.md`. |
| 2026-07-07 | Existing Flutter code (`members_page.dart`, `new_conversation_page.dart`, `messaging_api_service.dart`) + REST route index | Members Directory — mined from code + prior HAR + route index, no new capture | Direct code reading + grep | Confirmed 0% coverage: no API calls, no navigation on member cards (verified via grep), all 4 action buttons decorative. Full `buddyboss/v1/members` 12-route surface confirmed, incl. previously-uncross-referenced `avatar`/`cover` endpoints relevant to the next audit (Profile). Full writeup in new `members.md`. |
| 2026-07-07 | Existing Flutter code (`profile_page.dart`, `profile_setup.dart`, `edit_profile_page.dart`, `change_profile_photo_page.dart`, `user_profile_model.dart`) + REST route index | Profile/XProfile — mined from code + route index, no new capture | Direct code reading + grep (incl. grep confirming `updateProfileFields`/`XProfileFields` no longer exist anywhere) | **Major correction:** `K54_PROJECT_HANDOFF.md`'s claimed onboarding fix (Firebase removed, BuddyBoss xprofile wired) is not present in the checked-out code — `profile_setup.dart` still has the original Firebase-null-user silent-fail bug and is still reachable. New, previously-undocumented bug: `EditProfilePage` writes to a disconnected static in-memory model and shows a false "success" message. Full writeup in new `profile-xprofile.md`. |
| 2026-07-07 | Existing Flutter code (`friends_page.dart`, `friend_model.dart`) + REST route index | Friends/Connections — mined from code + route index, no new capture | Direct code reading + grep | Confirmed 0% coverage, consistent with pre-audit expectations (no drift this time). `Friend` model confirmed dead code via grep. Full 2-route `buddyboss/v1/friends` surface confirmed. Full writeup in new `friends.md`. |
| 2026-07-07 | Existing Flutter code (`screen/groups_page.dart`, `communication/groups_page.dart`) + REST route index | Groups — mined from code + prior HAR + route index, no new capture | Direct code reading + grep | Confirmed 0% coverage on both surfaces; confirmed they show genuinely different fake datasets/designs (not duplicated code), reinforcing the two-surfaces question is a real product decision. Full 33-route combined groups+forums surface confirmed, incl. forum moderation tools (merge/split/move) with zero corresponding UI anywhere. Full writeup in new `groups.md`. |
| 2026-07-07 | Existing Flutter code (`notifications_page.dart`) + REST route index + prior HAR2 heartbeat capture | Notifications — mined from code + prior HAR + route index, no new capture | Direct code reading | Confirmed 29% capability coverage — highest of the near-zero features, because the dummy screen's mark-read/mark-all-read/empty-state interactions genuinely work locally (first 0-Decorative-UI feature in this audit). Confirmed no unread badge on the entry icon despite `UnreadBadge` already existing and working for Messages. Confirmed zero deep-linking. Full 3-route REST surface confirmed (incl. `bulk/read`). Full writeup update in `notifications.md`. |
| 2026-07-07 | Existing Flutter code (`screen/courses_page.dart`, `Profile/courses_page.dart`) + full REST route lists for both LMS plugins | Courses — mined from code + route index, no new capture. **Core 7 complete.** | Direct code reading + grep | Confirmed 0% coverage; filter dropdown confirmed cosmetic-only. `Profile/courses_page.dart` confirmed genuinely 0 bytes, no drift from `CLAUDE.md`. Pulled full (not just counted) route lists for `learnpress/v1`/`tutor/v1` — substantially upgrades the LearnPress-vs-Tutor evidence: LearnPress owns the entire course-taking write lifecycle (enroll/quiz/lesson-progress/own auth), Tutor is read-only. Full writeup in new `courses.md`. |
| 2026-07-07 | Existing Flutter code (`ai_page.dart`) + `k54-ai/v1` route existence (from earlier REST index fetch) | K54 AI Assistant — dedicated audit, mined from code + route index, no new capture. **All 8 core-scope features now audited.** | Direct code reading | Confirmed send button is a pure `print()` stub, zero network attempt. Confirmed 4-route backend exists with zero behavioral evidence — lowest Evidence Confidence of any feature in this audit (~21%). Two next steps identified: JWT test call, or PHP source access (K54's own plugin). Full writeup in new `ai-assistant.md`. |
| 2026-07-07 | All 9 per-feature audit files + parity-scorecard.md | Final gap analysis and roadmap — pure synthesis, no new capture | Cross-referencing existing docs | **Phase 1 core deliverable complete.** Executive summary, 5-item cross-feature Confirmed Bugs list, 4-item Documentation Drift log, cross-cutting themes, staged Phase 2 sequencing recommendation (Stage 0: fix bugs → Stage 1: wire existing plumbing → Stage 2/3: build out by evidence-readiness → Stage 4: contingent on product/vendor decisions). See `gap-analysis.md`. |
| 2026-07-08 | K54 AI Assistant PHP source, provided directly by the user | K54 AI Assistant backend — ground-truth source, not a capture | Direct source review | **Largest single-pass Evidence Confidence jump in this audit (~21% → ~90%).** Full `/chat` and `/create-group` lifecycle documented: OpenAI Responses API (`gpt-4.1-mini`, non-streaming, 60s timeout, client-managed history, hardcoded Markdown-mandating system prompt), real BuddyBoss group creation. **⚠️ Confirmed both endpoints are unauthenticated in production** (permission callbacks always return true, plus an explicit REST-auth bypass filter for the whole namespace), no rate limiting — flagged as urgent, separate from the rest of the roadmap. Full classified code review (1 Confirmed Bug, 4 Security Risks, 1 Architectural, 2 Maintainability, 1 Performance finding) and updated implementation blueprint in `ai-assistant.md`. |
| 2026-07-07 | `GET https://k54global.com/wp-json/` (public, unauthenticated) | Full platform REST route discovery | Direct curl fetch + programmatic parse (842 routes) | **Major, zero-cost capture.** Corrected an earlier claim: `better-messages/v1/ai/*` (8 routes) and `getAIBots` confirm AI conversations are real — retracted the earlier "no evidence" statement. Discovered `better-messages/v1/app/*` — a likely official mobile-integration path (login, push token registration) not yet investigated, a higher-priority lead than the WebSocket route. Discovered a custom `k54-ai/v1` namespace (`chat`, `create-group`, `test`) — likely the real backend for the app's AI Assistant page, previously assumed to need requirements gathering. Confirmed `buddyboss/v1/activity`'s full 14-route surface (comments, pin, share, featured image, link preview) — large new Activity Feed gap, no capture needed to find it. Confirmed `buddyboss/v1/pusher`, `buddyboss/v1/friends`, `wpstream/v1`, `learnpress/v1` (incl. its own token-auth system), `tutor/v1`, Events Calendar's two API generations, and a second social-login namespace (`bb-social-login/v1`). Full detail in new `rest-route-index.md`. |
