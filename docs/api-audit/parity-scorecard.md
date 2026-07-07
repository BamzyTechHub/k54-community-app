# Parity Scorecard — Running Summary

One row per completed feature audit. Numbers are computed from an explicit capability list shown in that feature's own file (see the Parity Scorecard section there) — not asserted. Definitions are in `README.md`'s Parity Scorecard section; short version: Website is always the 100% baseline, Flutter/Parity measure the app against it, Evidence Confidence measures how much of *this table itself* is ✅ vs. 🟡/🔴 rather than how complete the app is.

| # | Feature | Website | Flutter | Parity | Confirmed Bugs | Missing Features | Decorative UI | API Coverage | Evidence Confidence |
|---|---------|---------|---------|--------|-----------------|--------------------|-----------------|----------------|------------------------|
| 1 | Messaging | 100% | 25% | 25% | 1 (open) | 14 | 0 | ~0% vs. Better Messages (native system); ~71% vs. BuddyBoss (the API the app actually uses) | ~67% |
| 2 | Activity Feed | 100% | 20% | 20% | 2 | 11 | 12 | 21% | ~71% |
| 3 | Members Directory | 100% | 0% | 0% | 0 | 9 | 8 | 0% (this screen) | ~63% |
| 4 | Profile / XProfile | 100% | 20% | 20% | 2 | 6 | 1 (+1 minor) | ~0% (write surface) | ~70% |
| 5 | Friends | 100% | 0% | 0% | 0 | 7 | 7 | 0% | ~61% |
| 6 | Groups | 100% | 0% | 0% | 0 | 14 | 11 | 0% | ~65% |
| 7 | Notifications | 100% | 29% | 29% | 0 | 4 | 0 | 0% | ~71% |
| 8 | Courses | 100% | 0% | 0% | 0 | 10 | 1 | 0% | ~50% |
| 9 | K54 AI Assistant | N/A* | 0% | N/A* | 1 (backend) | 7 | 3 | 0% | ~90% |

\* K54 AI Assistant's Website Coverage/Parity are marked N/A, not 0% or 100% — unlike every other feature, it's unconfirmed whether a website equivalent even exists to serve as the parity baseline. Flutter Coverage (0%) and everything else stand independent of that question.

## Core 7 complete — summary

Average Flutter Coverage across the 7 priority-ordered features (Activity Feed through Courses, excluding Messaging which was audited separately/first): **~10%**. Including Messaging: **~12%**. Four of the eight audited features are at literal 0% (Members, Friends, Groups, Courses) — not because those areas are hard, but because they're simply not built yet, confirmed by direct code inspection rather than assumed.

## K54 AI Assistant — dedicated audit, now backed by actual source

Started as the least-evidenced feature in this audit (~21%). The user then provided the actual PHP source for the `k54-ai/v1` backend, which pushed Evidence Confidence to **~90%** — the single largest confidence jump of any pass in this whole project, because source code is categorically stronger evidence than any amount of black-box testing.

**⚠️ This also surfaced the most serious finding in the entire audit: both `/chat` and `/create-group` are completely unauthenticated in production** (a blanket `permission_callback => '__return_true'` plus an explicit filter that forces WordPress's own REST auth check to always pass for this namespace), with no rate limiting anywhere. Practically: any anonymous internet visitor can currently drain K54's OpenAI budget and create real, live groups on the community site. This is flagged as a candidate for urgent, separate attention — not something that should wait for the rest of this roadmap's sequencing, which is scoped to feature parity, not active security exposure. See `ai-assistant.md`'s Code Review section for the full classified findings (1 Confirmed Bug, 4 Security Risks, 1 Architectural, 2 Maintainability, 1 Performance).

**All 8 core-scope features are now audited.** Next per the standing plan: platform configuration documentation (needs WP Admin screenshots), then the final gap analysis and prioritized implementation roadmap.

## Reading this table honestly

- **Messaging's API Coverage is split into two numbers on purpose** — collapsing "0% of the website's real system" and "71% of the alternate API the app uses instead" into one figure would hide the actual architectural gap (not using Better Messages at all) behind the smaller functional gap (basic messaging still technically works via BuddyBoss).
- **Low Parity numbers are not a verdict on session quality** — they reflect how much *more* was found once the audit went past "does the basic feature work" into "does it match everything the website actually does" (reactions, calls, translation, pin/mute for Messaging; comments/pin/share/media for Activity Feed). Both features had zero known scope before this audit that's now fully itemized and actionable.
- **Members Directory's 0% is a genuine confirmed zero, not a measurement artifact** — unlike Activity Feed (which has a real, working `FutureBuilder` state machine with some capabilities functioning), Members Directory makes no network calls of any kind and has no navigation wired at all. It also has 0 Confirmed Bugs (as opposed to Activity Feed's 2) because nothing here is a regression in working code — it's all inert-by-construction, which is a different (cheaper to reason about, since nothing needs debugging) category of work than fixing something broken.
- **Notifications is the first feature with zero Decorative UI** — its dummy screen's mark-read/mark-all-read/empty-state interactions are genuinely working local behavior, just against fake data rather than a server. That's a meaningfully cheaper starting point than Members/Friends/Groups, where the equivalent controls do nothing at all.
- **Three features have now turned up real, currently-shipping bugs** (not just gaps): Messaging's `InboxController` disposal crash, Activity Feed's like-toggle full-reload regression and image-drop-on-publish bug, and Profile's two bugs (a Documentation-Drift regression in onboarding, plus a previously-unknown fake-success bug in Edit Profile). These are cheap, high-value fixes relative to the rest of what's documented — worth prioritizing independently of the broader parity work.
- **Profile is the first feature where a prior project document's claimed fix was directly contradicted by the current code**, not just an assumption about the website. Worth treating `K54_PROJECT_HANDOFF.md`'s other "fixed this session" claims (there are several, for other features) with the same skepticism rather than trusting them by default — see `profile-xprofile.md`'s Discrepancy Log for the specifics.

Updated after each feature audit completes.
