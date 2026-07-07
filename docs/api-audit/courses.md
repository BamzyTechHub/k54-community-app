# Feature: Courses / LMS

## Status
- **Website:** Partial. Both LMS plugins' full REST surfaces confirmed via route index. **New, stronger evidence on the LearnPress-vs-Tutor question** — see below. No response bodies captured, no website UI behavior observed.
- **Flutter:** Confirmed via direct code reading — `lib/screen/courses_page.dart` is 100% dummy data, zero API wiring, zero navigation (no course detail/lesson/quiz view exists anywhere in the app). The filter dropdown changes its own displayed value but never actually reorders the list. `lib/Profile/courses_page.dart` confirmed genuinely 0 bytes — matches `CLAUDE.md`'s dead-code flag exactly, no drift here.
- **Figma:** Not yet reviewed.

## Network Behavior

### Which LMS is "the real one" — evidence upgraded this pass

Previously flagged as "route richness is a lead, not proof." Having now pulled the **full** route lists for both (not just counts), the evidence is considerably stronger:

```
learnpress/v1 — full write/action surface for actually taking a course:
  POST /courses/enroll        POST /courses/finish        POST /courses/retake
  POST /courses/verify-receipt
  POST /lessons/finish
  POST /quiz/start             POST /quiz/check_answer     POST /quiz/finish
  POST /token  POST /token/register  POST /token/validate  (own auth system)
  GET,POST,PUT,PATCH /users/{id}   POST /users/change-password   POST /users/delete   POST /users/reset-password

tutor/v1 — read-only, no course-taking action endpoints at all:
  GET /courses  GET /courses/{id}  GET /lessons  GET /quizzes  GET /quizzes/{id}
  GET /topics  GET /course-announcement/{id}  GET /course-contents/{id}
  GET /course-rating/{id}  GET /author-information/{id}  GET /quiz-attempt-details/{id}  GET /quiz-question-answer/{id}
  (only write route: /ecommerce-webhook — a payment-gateway callback, not a user action)
```

🟡 **High confidence** (upgraded from the earlier "lead, not proof"): LearnPress's API is built for full headless/mobile course-taking — enroll, finish lessons, take quizzes (start/answer/finish), retake, and even manage the user's own account (password change/reset/delete), plus its own dedicated token-issuance system, which only makes sense for a plugin expecting non-browser clients. Tutor LMS's API is read-only display data with no way to actually enroll in or progress through a course via REST at all — its one write endpoint is a payment webhook, not a user action. This is now a much stronger signal than route counts alone, though still 🟡 not ✅ — it hasn't been confirmed by observing which one the live site's member-facing Courses page actually calls.

### LearnPress's separate auth system — genuine untested gap
```
POST /learnpress/v1/token            POST /learnpress/v1/token/register       POST /learnpress/v1/token/validate
```
Confirmed to exist. Whether the app's existing JWT (from `/jwt-auth/v1/token`) works against LearnPress's own routes, or whether a separate `learnpress/v1/token` exchange is required, is **directly testable the same way the Better Messages JWT compatibility was** (a curl call with the existing bearer token against a LearnPress GET endpoint first, since `courses`/`courses/{id}` are public GETs that may not even require auth to test the baseline) — this is a real, fillable evidence gap, not something inferable from code or route lists alone.

### Course structure endpoints (LearnPress)
```
GET /learnpress/v1/sections/sections-by-course-id/{course_id}
GET /learnpress/v1/section-items/items/{section_id}
```
Confirms a Course → Section → Item hierarchy (standard LMS structure) — course detail views would need to walk this chain, not just fetch a flat course object.

### App — none
No courses-related API call exists anywhere in the codebase.

## Models to create/change
No `Course`/`Lesson`/`Quiz` model exists — dummy data is `List<Map<String, String>>` (`image`, `title`, `lessons` [a count as a string], `duration`, `instructor`). None of these fields map cleanly onto either LMS's confirmed schema (neither response body has been captured, but the LearnPress route structure implies a course object wouldn't carry a flat lesson-count string, it'd require walking sections/items).

## Functional Behavior

**Filter dropdown:** confirmed via code read — `onChanged` only updates `selectedFilter`'s displayed value via `setState`; the `courses` list itself is never sorted/filtered by it (no `.sort()`/`.where()` call exists anywhere referencing `selectedFilter`). Same "looks interactive, does nothing" pattern as Groups' tab switcher and Members' sort dropdown.

**Course cards:** confirmed via grep — no `GestureDetector`/`InkWell`/`Navigator` anywhere in the file. No course-detail view exists to navigate to even if a card were tappable — course viewing, lesson viewing, and quiz-taking have **zero UI presence** anywhere in the app, not decorative, just absent (matching the same "no UI at all" pattern found for Friends' request/accept-reject and Groups' forums).

**State machine:** none — no async operation exists.

## Role / Account-Status Variations
Not tested. Worth flagging: course *access* (enrolled vs. not, free vs. paid) is inherently role/status-dependent in any LMS, more so than most other features audited — this will need real test-account variation (an enrolled account vs. a non-enrolled one) once real data flows, not just a single-role smoke test.

## Undocumented / Plugin-Specific Behavior
`courses/verify-receipt` (LearnPress) — implies a payment/receipt-verification step exists in the enrollment flow, unconfirmed what triggers it or what "receipt" means in this context (could be tied to a WooCommerce-style purchase, unconfirmed).

## Open Questions
- Does the app's existing JWT work against LearnPress's REST routes, or does `learnpress/v1/token` need to be exchanged separately? Directly testable, not yet tested.
- Which plugin does the live website's own Courses/LMS page actually render against? Would need a website-side capture (HAR with content on that page) to settle definitively, since the route-richness evidence, while now strong, is still inference.
- Full response schema for any course/lesson/quiz endpoint on either plugin — none captured.
- What does `courses/verify-receipt` actually gate?
- Is there a certificate/completion-tracking endpoint on either plugin? Not observed in either route list — may not exist, or may live under an unexplored sub-path.

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | `lib/Profile/courses_page.dart` | `CLAUDE.md`: "EMPTY FILE (0 bytes), unused, delete" | Confirmed via `wc -l`: genuinely 0 bytes | N/A — confirms prior flag exactly, no drift |
| 2 | Course filter dropdown | UI suggests selecting a sort order re-orders the list | Confirmed via code read: only changes its own displayed value, list order never changes | **UI-only Placeholder** |
| 3 | Which LMS backs the live site | Originally "unconfirmed which plugin, if any" | Full route lists now show a strong asymmetry (LearnPress has the entire course-taking lifecycle as write endpoints, Tutor is read-only) — upgraded from 🔴 to 🟡, still not ✅ | N/A — evidence strengthened, not a discrepancy between sources |

## Parity Scorecard

**Capability list this score is computed from** (10 capabilities): browse courses, view course detail, enroll, view lesson content, mark lesson complete, take a quiz, view quiz results, view instructor info, filter/sort courses, view course reviews/ratings.

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **0 of 10** = **0%**
- **Parity:** 0%
- **Confirmed Bugs:** 0 (inert by construction, same reasoning as Members/Friends/Groups)
- **Missing Features:** 10 (all of them)
- **Decorative UI:** 1 (the filter dropdown — the only interactive-looking control on this screen)
- **API Coverage:** 0 of 43 combined confirmed LearnPress+Tutor routes called (0%)
- **Evidence Confidence:** ✅ 4 (dummy data confirmed, no navigation confirmed via grep, filter-dropdown no-op confirmed via code read, `Profile/courses_page.dart` empty-file status confirmed) / 🟡 2 (LearnPress-vs-Tutor lean, LearnPress token-auth requirement) / 🔴 4 (any response schema, which plugin the website actually uses, `verify-receipt`'s purpose, whether a certificate/completion endpoint exists at all) → **(4 + 1)/10 = 50%** — the lowest Evidence Confidence of the core 7, reflecting that this feature has had zero live capture at any point, unlike every other feature audited so far.
