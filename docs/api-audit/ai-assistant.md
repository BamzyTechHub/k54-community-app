# Feature: K54 AI Assistant

First-class, custom-built K54 feature (not part of Better Messages' `ai/*` — see `messaging-better-messages.md` for that separate system).

## ⚠️ Critical security finding — see PHP Backend Code Review below

Both `/chat` and `/create-group` are unauthenticated on production (permission callback always returns true, plus an explicit auth-bypass filter for the whole namespace). No rate limiting. Treat as an active exposure, not a documentation footnote — see the Code Review section for full detail and recommend confirming with the user whether this is live before anything else in this file is acted on.

## Status
- **Website:** Still unknown whether a user-facing website equivalent exists — not resolved by the source code (the PHP only shows the API layer, not whether any website page calls it).
- **Backend:** ✅ **Confirmed via PHP source** (provided directly by the user, 2026-07-08) — complete route definitions, handler logic, auth model, and OpenAI integration are now known precisely, not inferred. This replaces nearly every 🔴 Hypothesis from the previous pass.
- **Flutter:** Confirmed via direct code reading (prior pass) — `lib/screen/ai_page.dart` is a pure UI shell, send button is a `print()` stub, zero network call.

## Complete REST endpoint inventory (✅ Confirmed from source)

| Endpoint | Method | Permission callback | Handler |
|---|---|---|---|
| `/k54-ai/v1/chat` | POST | `__return_true` (no check) | `k54_ai_handler()` |
| `/k54-ai/v1/create-group` | POST | `__return_true` (no check) | `k54_create_group()` |
| `/k54-ai/v1/test` | GET | `__return_true` (no check) | inline closure → `{"success": true, "message": "K54 API Working"}` |

## Authentication model (✅ Confirmed — this is the headline finding)

```php
add_filter('rest_authentication_errors', function($result) {
    if (!empty($result)) return $result;
    $request_uri = $_SERVER['REQUEST_URI'] ?? '';
    if (strpos($request_uri, '/wp-json/k54-ai/v1/') !== false) {
        return true;   // forces "no auth error" regardless of credentials
    }
    return $result;
}, 1);
```
This runs *in addition to* every route's `permission_callback => '__return_true'` — it's not just that these routes don't check a capability, WordPress's own REST authentication error check is explicitly disabled for the whole namespace. A request with a valid JWT bearer token still gets correctly identified via the JWT plugin's normal `determine_current_user` flow (so the app's own calls would carry the right user ID) — but a request with **no credentials at all** is not rejected either, and proceeds with `get_current_user_id()` returning `0`. There is no code path in either handler that checks `is_user_logged_in()` or rejects an anonymous caller.

## `/chat` — complete request/response lifecycle (✅ Confirmed)

**Request:** `POST /k54-ai/v1/chat`, JSON body `{"message": "...", "history": [{"role": "...", "content": "..."}, ...]}`.

**Processing (`k54_ai_handler`):**
1. `message` sanitized via `sanitize_textarea_field`.
2. `history` (client-supplied, no server-side persistence anywhere — see below) sliced to the **last 10 turns** (`array_slice($history, -10)`), concatenated into a plain-text `ROLE: content` block.
3. A large, hardcoded system prompt is assembled (see below) and concatenated with the history block and the latest message into one `$final_input` string.
4. A single synchronous `wp_remote_post` to **`https://api.openai.com/v1/responses`** (OpenAI's Responses API, not Chat Completions), model **`gpt-4.1-mini`**, `temperature: 0.7`, `timeout: 60` seconds, with the **`web_search_preview`** tool enabled.
5. Response parsed: iterates `$data['output']`, collects `content[].text` from items where `type === 'message'` and content `type === 'output_text'`, concatenating into `$reply`.
6. Returns `rest_ensure_response(['reply' => $reply])` — **always HTTP 200**, even on failure (see Code Review, Confirmed Bug #1).

**Non-streaming, confirmed** — this is one blocking request/response, not SSE/chunked/WebSocket. The 60-second timeout means the Flutter client needs a loading state that tolerates up to a minute, not a typical few-hundred-ms request.

**Error paths, both still 200 OK with a text message in `reply`:**
- `is_wp_error($response)` → `{"reply": "K54 AI connection error."}`
- Empty extracted reply → `{"reply": "K54 AI could not generate a response."}`

There is no structured error field, status code, or error type anywhere in this endpoint's contract — a client can only detect failure by string-matching against these two known phrases, which is brittle.

## System prompt (✅ Confirmed exact content)

Hardcoded in `k54_ai_handler`. Mandates: a specific Markdown response structure (`### Initial Highlight`, `## Section Header`, `> blockquote recommendation`, bullet points, a "CASE STUDY:" section), behavioral rules (never center text, stay conversational, follow conversation context, handle "summarize/improve/template" follow-ups specially against the *previous* response), and a strict source-citation format for anything touching news/trends/statistics/external info/code/advice — links must be Markdown (`[Label](url)`), never raw URLs, never hallucinated, placed at the end.

**Direct implication for the Flutter blueprint:** the app needs a **Markdown renderer**, not the current static placeholder text — headers, blockquotes, bullet lists, and links all need to render correctly, or the AI's actual output will look broken/garbled in a plain `Text` widget. The app already depends on `flutter_html` for HTML rendering elsewhere (activity feed captions); a Markdown-specific package (e.g. `flutter_markdown`) would be a new dependency to evaluate, not something already available.

## Conversation history handling (✅ Confirmed)

**No server-side persistence exists at all.** `history` is entirely client-supplied per request; the server only truncates to the last 10 turns for prompt-building purposes — it never stores, reads, or associates history with a user account anywhere in this code. This means:
- The Flutter app is **fully responsible** for storing conversation history locally and resending it on every `/chat` call.
- There is no "resume my conversation from another device" capability at the API level — it would have to be built as a separate, new feature (e.g. the app persisting history to its own storage or a different endpoint entirely), not something this backend already supports.
- Since `history` is client-supplied and the endpoint is unauthenticated, a caller can inject arbitrary `role`/`content` values into the context sent to OpenAI — a prompt-injection surface, compounded by the lack of authentication (no accountability for who's sending what).

## Group creation flow (✅ Confirmed)

**Request:** `POST /k54-ai/v1/create-group`, JSON body `{"groupName": "...", "description": "...", "privacy": "public"|"private"|"hidden"}`.

**Processing (`k54_create_group`):**
1. Guards on `groups_create_group` existing (BuddyBoss Groups component active) — if not, returns `{"success": false, "message": "BuddyBoss Groups not found."}` (200 OK).
2. Logs the **raw, unsanitized request params** to the PHP error log (`error_log('K54 GROUP DATA: ' . print_r($params, true))`) before any sanitization — see Code Review.
3. Sanitizes `groupName`/`description`; `privacy` is lowercased and mapped to BuddyBoss's `status` field (`private`→`private`, `hidden`→`hidden`, anything else→`public`, a safe default).
4. Calls `groups_create_group(['creator_id' => get_current_user_id(), 'name' => ..., 'description' => ..., 'status' => ...])` directly — this is a real, live BuddyBoss group creation, not a draft/preview.
5. Success: `{"success": true, "group_id": ..., "group_url": ..., "message": "Group created successfully."}` (via `bp_get_group_permalink`). Failure (`groups_create_group` returns falsy): `{"success": false, "message": "Group creation failed."}`.

**Confirms the UI-intent hypothesis from the prior audit pass** — the app's "Create NGO Community"/"Create Church Group"/"Start Study Group" quick actions really are meant to map to this endpoint, not `/chat`.

## PHP Backend Code Review

Classified per your taxonomy. This reviews the backend code itself — separate from the Flutter parity blueprint below, which describes building against this backend *as it currently behaves*, bugs included, since that's what "parity" means. Improvement recommendations here are not prerequisites for the blueprint.

| # | Finding | Classification | Detail |
|---|---|---|---|
| 1 | Both endpoints fully unauthenticated in production | **Security Risk (High)** | `permission_callback => '__return_true'` on every route, plus an explicit `rest_authentication_errors` bypass for the whole namespace. Any anonymous caller can invoke either endpoint. See the top of this file. |
| 2 | No rate limiting anywhere | **Security Risk (High)** | Combined with #1: unlimited unauthenticated calls to a paid OpenAI key, and unlimited group creation. A direct cost-drain/spam vector, not just a theoretical gap. |
| 3 | OpenAI API key hardcoded in source | **Security Risk (Medium)** | Not read from a WP option, environment variable, or secrets store. Standard exposure risk via version control, backups, or accidental file exposure. |
| 4 | Raw, unsanitized request params logged verbatim on every group-creation call | **Security Risk (Low-Medium)** | `error_log('K54 GROUP DATA: ' . print_r($params, true))` runs before sanitization. Combined with #1, an anonymous caller can write arbitrary content into the server's error log at will, with no limit — minor info-disclosure and log-flooding risk, and unnecessary in production regardless of the auth issue. |
| 5 | All error conditions return HTTP 200 with an embedded text message, never a real error status | **Confirmed Bug** | `is_wp_error`, empty reply, and missing-BuddyBoss-Groups cases all return `rest_ensure_response([...])` with implicit 200. A client can only detect failure by string-matching known phrases (`"K54 AI connection error."`, `"K54 AI could not generate a response."`, `success: false`) — fragile, breaks silently if wording ever changes. |
| 6 | No server-side conversation persistence | **Architectural Improvement** | Not a defect — a legitimate stateless-API design choice — but a real constraint the Flutter app must be built around (full local history management, no cross-device resume without separate work). Documented here so it's a deliberate decision, not a surprise. |
| 7 | Synchronous 60-second-timeout OpenAI call under PHP-FPM | **Performance Improvement** | A burst of concurrent `/chat` requests can each tie up a PHP worker for up to 60 seconds. Combined with #1/#2 (unauthenticated, unlimited), this is a realistic scalability/availability concern, not just a slow-request inconvenience. |
| 8 | System prompt hardcoded inline in the handler | **Maintainability Improvement** | Any prompt/behavior tuning requires a code deployment. Worth flagging given how detailed (and likely to be iterated on) this prompt is. |
| 9 | No defensive fallback if OpenAI's response shape changes | **Maintainability Improvement** | The `$data['output'][]['content'][]['text']` extraction assumes a specific nested shape with only a final `empty($reply)` catch-all. Low near-term risk, brittle against upstream API changes. |
| 10 | Input sanitization on user-supplied text fields | **Positive finding, not a defect** | `sanitize_textarea_field`/`sanitize_text_field` are correctly applied to `message`/`groupName`/`description` — worth crediting explicitly rather than only listing problems. |

## Flutter vs. backend — gap comparison

| Backend capability (confirmed) | Flutter status |
|---|---|
| `/chat` — send message + history, get AI reply | Not called at all — send button only `print()`s |
| Markdown-structured responses (headers/quotes/bullets/citations) | No rendering capability exists — static placeholder text only |
| Client-managed conversation history | No local storage/history model exists at all |
| `/create-group` — AI-assisted group creation | Not called; UI's quick-action copy already gestures at this intent but nothing is wired |
| Long-running request (up to 60s) | No loading-state handling exists (nothing calls the network at all yet) |
| Text-based error signaling (200 + message string) | N/A — no error handling exists since no calls are made |

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Backend auth model | Prior pass: "likely JWT given the site-wide pattern, but genuinely untested" | Source confirms: not just untested-but-probably-fine — actively, deliberately unauthenticated via an explicit bypass filter | **Documentation Drift** (the prior hedge undersold the actual state) + **Security Risk** |
| 2 | Chat-vs-create-group routing intent | Prior pass: inferred from UI copy only, marked 🟡 | Source confirms `create-group` is a real, distinct, fully-implemented endpoint separate from `/chat` — the UI-intent inference was correct | N/A — confirms prior inference, upgrades confidence from 🟡 to ✅ |
| 3 | Streaming vs. non-streaming | Open question | Confirmed non-streaming, single blocking call, 60s timeout | N/A — resolves an open question |

## Parity Scorecard (updated)

**Capability list, refined now that real backend behavior is known** (7 capabilities): send chat message, receive + render AI reply (Markdown), maintain local conversation history across turns, create a group via AI, handle long-running requests gracefully, handle text-embedded error states, respect the confirmed capability set (no streaming, no attachments observed, no rate-limit feedback needed client-side since none exists server-side).

- **Website Coverage:** still N/A — unresolved whether a website equivalent exists (unaffected by the source code, which only covers the API layer).
- **Flutter Coverage:** **0 of 7** = **0%** — unchanged, since the Flutter side wasn't touched by this pass.
- **Parity:** N/A (see Website Coverage)
- **Confirmed Bugs:** 1 (backend: HTTP-200-always error signaling — see Code Review #5; this is a backend bug, not a Flutter one, tracked here since it directly affects how the Flutter client must be built)
- **Missing Features:** 7 (all — but now precisely scoped instead of provisional)
- **Decorative UI:** 3 (unchanged — send button, quick-action buttons, search-suggestion chips)
- **API Coverage:** 0 of 3 confirmed routes called (0%)
- **Evidence Confidence:** ✅ 13 (every item in this file except the website-equivalent question and the two items below) / 🟡 1 (whether a website equivalent exists at all) / 🔴 1 (whether this is actually deployed live on production — the source was provided as a file, not confirmed as the currently-active version) → **(13 + 0.5)/15 ≈ 90%** — up from ~21%, the largest single-pass confidence jump in this audit, because source code is categorically stronger evidence than black-box testing.

## Implementation Blueprint

Builds against the backend **as it currently behaves**, including its confirmed quirks (200-always errors, no server-side history, 60s timeout) — this describes reaching parity with what exists, not a wishlist. Backend improvement opportunities are tracked separately in the Code Review above, not folded in here.

### Reuse assessment
No existing Flutter chat/messaging code is directly reusable for the *transport* (this is a single POST/response, not the messaging module's polling/WS/repository machinery) — but the **UI patterns** from `lib/messaging/screens/chat_page.dart` (bubble rendering, input bar, send-button state) are a reasonable visual/structural starting point, adapted for single-request/response instead of a live thread.

### Complete REST endpoints / Authentication requirements
See above. Note for whoever builds this: the backend doesn't require the app's JWT at all currently (auth is bypassed), but the app should **still send it anyway** — partly so `get_current_user_id()` correctly attributes group creation to the real user instead of `0`, and partly so behavior doesn't change unexpectedly if the security issue above gets fixed and auth becomes enforced later.

### Request sequence
1. User sends a message → append to local history → POST `/chat` with `{message, history: last N turns}`.
2. Await response (design for up to 60s, not a typical fast round-trip).
3. Render `reply` as Markdown, append to local history as an assistant turn.
4. For group-creation intents (either via quick-action buttons or detected some other way — the backend doesn't do intent classification, that's a client or a separate-prompt decision) → POST `/create-group` directly with structured fields, not through `/chat`.

### Models to create
- `AiChatMessage` — `role` (`user`/`assistant`), `content`, timestamp. Purely local, no server ID since nothing is persisted server-side.
- `AiConversation` — local-only, ordered list of `AiChatMessage`, needs its own local persistence strategy (e.g. `shared_preferences`/local DB) since the backend provides none.

### Repository / Service layer
`K54AiApiService` (raw HTTP, matching the project's established service-layer convention) — `chat({message, history})`, `createGroup({groupName, description, privacy})`, `test()`. A repository layer isn't strictly necessary given there's no caching/dedup concern (unlike messaging), but keeping the pattern consistent with the rest of the app is reasonable.

### State management flow
`loading` (potentially long, needs a distinct "still thinking" state beyond a quick spinner — 60s is long enough that a static spinner risks feeling broken) / `error` (parsed from the two known text phrases, since there's no structured error field) / `success`.

### Error handling
Must string-match `"K54 AI connection error."` / `"K54 AI could not generate a response."` / `success: false` bodies, since there's no HTTP status or structured error code to key off. Brittle by construction (backend issue, not fixable client-side) — worth a comment in the implementation noting why.

### Media/Markdown handling
Needs a Markdown-capable rendering widget (new dependency candidate — `flutter_markdown` or similar) to correctly display headers, blockquotes, bullets, and citation links per the confirmed system prompt's mandated format.

### Compatibility risks
The security issue above is the biggest one — if/when it's fixed (auth enforced), the app's behavior shouldn't change as long as it's already sending its JWT, per the Authentication note above. The 200-always error convention and lack of streaming are both stable-but-awkward constraints to design around, not things expected to change soon.

### Parity approach
1. Basic `/chat` round-trip with Markdown rendering and local history — the core loop.
2. `/create-group` wiring behind the existing quick-action buttons.
3. Loading-state UX tuned for the realistic 60s worst case.
4. Revisit once/if the security issues are addressed, since that may change what the app needs to send (e.g. if rate-limit headers get added later).
