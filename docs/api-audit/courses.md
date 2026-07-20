# Feature: Courses / LMS

## Status
- **Website:** RESOLVED 2026-07-19 — **Tutor LMS confirmed as the real, actively-administered LMS**, via direct WP admin screenshot (not inference): "Tutor LMS" is the highlighted/active admin section, with a real published course "K54 Global Growth Program" (author: Ezekiel, Free, Topic:1/Lesson:2/Quiz:0/Assignment:0) — the exact same title already used as the app's placeholder Courses data. LearnPress is installed but shows no evidence of active use. This **overturns** the route-richness-based lean toward LearnPress recorded below (kept for the record, not deleted, since it's a useful example of inference being wrong) — direct observation of the admin UI beats route-surface inference. The remaining real blocker is authenticating against `tutor/v1` (401 unauthenticated, see below), not a which-LMS question.
- **Flutter:** File paths below are stale (pre-dated this session's `lib/features/` restructure) - the real file is `lib/features/courses/screens/courses_page.dart`. Still 100% dummy data pending Tutor LMS auth, but the filter-dropdown no-op flagged below is now **fixed** (2026-07-18 pass): the filter is a real popover and actually re-sorts the dummy list (title A-Z/Z-A for real; "release date" has no real date field yet so newest/oldest uses authored order and its reverse). Still zero navigation - no course detail/lesson/quiz view exists anywhere in the app. No `lib/Profile/courses_page.dart` file exists in the current structure (the empty-file flag was against the old pre-restructure layout).
- **Figma:** Reviewed 2026-07-18 - course card grid, filter popover, and header now match the approved design; see session commit history.

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

~~🟡 High confidence~~ **SUPERSEDED 2026-07-19**: this route-richness-based lean toward LearnPress turned out to be wrong. A direct WP admin screenshot showed Tutor LMS as the actively-administered plugin with real course content, while LearnPress showed no evidence of use. Kept the original reasoning below as a record of *why* the inference pointed the wrong way (Tutor LMS's REST surface being read-only-with-a-payment-webhook is real and still true - it just doesn't mean LearnPress is the one actually in use; a plugin can have a richer REST API without being the one an admin actually chose to run). Lesson: route-surface inference is a lead, never a substitute for looking at the actual admin panel.

Original reasoning (historical): LearnPress's API is built for full headless/mobile course-taking — enroll, finish lessons, take quizzes (start/answer/finish), retake, and even manage the user's own account (password change/reset/delete), plus its own dedicated token-issuance system, which only makes sense for a plugin expecting non-browser clients. Tutor LMS's API is read-only display data with no way to actually enroll in or progress through a course via REST at all — its one write endpoint is a payment webhook, not a user action.

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
- ~~Which plugin does the live website's own Courses/LMS page actually render against?~~ **RESOLVED 2026-07-19**: Tutor LMS, confirmed via direct WP admin observation - see Status above.
- ~~Does the app's existing JWT work against `tutor/v1`'s routes?~~ **RESOLVED 2026-07-19**: yes, the JWT is recognized fine (401→403 once logged in) - but `tutor/v1/courses` and `tutor/v1/topics` are both permission-gated regardless (403 `rest_forbidden` even for a real logged-in member account, not just unauthenticated). The real course catalog data comes from `GET /wp/v2/courses` instead (WordPress's own post-type REST route, no special capability needed) - confirmed live, full course object with real title/content/featured_media/taxonomies pulled successfully.
- **New, confirmed blocker**: lesson/topic/quiz *detail* has no working path yet. Checked for a `wp/v2` post type (the same trick that unlocked the course catalog) - none exists (`lp_course`/`lp_quiz` are LearnPress's, not Tutor's; no `lesson`/`topic`/`quiz` post type registered for Tutor at all). The course object itself (`wp/v2/courses/{id}?_embed`) doesn't embed curriculum data either - just standard post fields. `tutor/v1/topics`/`tutor/v1/lessons` remain the only known paths, and both return the same 403 as `tutor/v1/courses` did. This might require enrollment in the course to unlock (untested - worth checking whether this specific test account is actually enrolled in "K54 Global Growth Program" before concluding it's a hard wall), or a site-side capability grant for regular members. Not something fixable from the Flutter app alone.
- Full response schema for any Tutor LMS course/lesson/quiz endpoint — the course object itself is now fully captured (see Status above); lesson/topic/quiz schema still blocked by the permission wall above.
- What does `courses/verify-receipt` (LearnPress) actually gate? Lower priority now that LearnPress isn't the confirmed target, but left open in case Tutor LMS auth is a dead end.
- Is there a certificate/completion-tracking endpoint on Tutor LMS? Not observed in its route list — may not exist, or may live under an unexplored sub-path.

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | `lib/Profile/courses_page.dart` | `CLAUDE.md`: "EMPTY FILE (0 bytes), unused, delete" | Confirmed via `wc -l`: genuinely 0 bytes | N/A — confirms prior flag exactly, no drift |
| 2 | Course filter dropdown | UI suggests selecting a sort order re-orders the list | Confirmed via code read: only changes its own displayed value, list order never changes | **UI-only Placeholder** |
| 3 | Which LMS backs the live site | Originally "unconfirmed which plugin, if any" | Full route lists now show a strong asymmetry (LearnPress has the entire course-taking lifecycle as write endpoints, Tutor is read-only) — upgraded from 🔴 to 🟡, still not ✅ | N/A — evidence strengthened, not a discrepancy between sources |
| 4 | Which LMS backs the live site (final) | 🟡 lean toward LearnPress, based on route-richness inference | Direct WP admin screenshot: Tutor LMS is the actively-administered plugin with real course content ("K54 Global Growth Program"); LearnPress shows no evidence of use | **Corrected Assumption** — the route-richness inference (#3) pointed the wrong way; direct observation overrides it |

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
