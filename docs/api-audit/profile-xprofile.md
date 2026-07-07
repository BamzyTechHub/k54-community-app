# Feature: Profile / XProfile

## Status
- **Website:** Partial. Full `buddyboss/v1/xprofile` (10 routes) + `buddyboss/v1/members/{user_id}/avatar`/`/cover` (cross-linked from `members.md`) REST surface confirmed via route index. Profile URL format (slug, not numeric ID) confirmed via HAR2.
- **Flutter:** Confirmed via direct code reading. **Viewing works** (real API). **Every editing surface is broken or fake, in three different ways** — see Discrepancy Log. This is the most broken feature audited so far.
- **Figma:** Not yet reviewed.

## ⚠️ Headline finding: three separate profile-editing screens, three separate failure modes

1. **Onboarding (`lib/profile_setup.dart`)** — still the pre-fix Firebase/Firestore version. `K54_PROJECT_HANDOFF.md` and `CLAUDE.md` both describe this file as rewritten this project to remove Firebase and call `BuddyBossService().updateProfileFields()`. **The file currently on disk is not that rewrite** — it imports `firebase_auth`/`firestore_service.dart`, calls `auth.currentUser` (always null, since the app never signs into Firebase — confirmed elsewhere in the codebase), and does `if (user == null) return;` with **no error shown to the user** — the exact silent-failure bug the handoff doc describes as historical and fixed. ✅ Confirmed reachable, not dead code: `face_id_verified.dart:81` and `touch_id_verified.dart:82` both navigate to `ProfileSetup()`.
2. **Edit Profile (`lib/Profile/edit_profile_page.dart`)** — a previously-**undocumented** bug, worse than #1: reads from and writes to `UserProfile`, a bare **static in-memory class** (`lib/models/user_profile_model.dart`) with hardcoded seed values (`name = "EVELYN"`, etc.). "Save Changes" mutates these static fields, shows **"Profile updated successfully,"** and pops back — zero network call, zero persistence, and **the actual `ProfilePage` doesn't even read from `UserProfile`** (it reads from `AuthService().getCurrentUser()`), so this screen's "save" doesn't affect what you see when you go back. This is a false-positive success message, not just a missing feature.
3. **Change Profile Photo (`lib/Profile/change_profile_photo_page.dart`)** — confirmed via grep: no `ImagePicker`, no `ApiService`/`BuddyBossService` import anywhere in the file, every `onTap` is empty. Fully decorative.

`BuddyBossService.updateProfileFields()` — the method the handoff doc describes as the real, working xprofile-save mechanism — **does not exist anywhere in the current codebase** (confirmed via grep across `lib/`). Neither does `XProfileFields` (the constants class with placeholder `-1` field IDs). `lib/utils/constants.dart` is now an empty file. Whatever work the handoff doc describes for this area is not present in what's currently on disk — flagging as the single largest Documentation Drift found in this audit.

## Network Behavior

### Website — confirmed via `GET /wp-json/` (existence only, no response bodies captured)
```
GET,POST                    /buddyboss/v1/xprofile/fields
GET,POST,PUT,PATCH,DELETE   /buddyboss/v1/xprofile/fields/{id}
GET,POST                    /buddyboss/v1/xprofile/groups
GET,POST,PUT,PATCH,DELETE   /buddyboss/v1/xprofile/groups/{id}
GET,POST,PUT,PATCH,DELETE   /buddyboss/v1/xprofile/{field_id}/data/{user_id}
POST,DELETE                 /buddyboss/v1/xprofile/repeater/{id}
POST,PUT,PATCH              /buddyboss/v1/xprofile/repeater/order/{id}
GET                         /buddyboss/v1/xprofile/search
GET                         /buddyboss/v1/xprofile/types
POST,PUT,PATCH              /buddyboss/v1/xprofile/update
```
New, not previously known: **`repeater`/`repeater/order`** — BuddyBoss supports repeatable field groups (e.g. multiple work experiences/education entries), a field type the app has no model for at all. `xprofile/search` — search members by profile field values (distinct from the members-directory name search). `xprofile/types` — field type definitions (text/dropdown/date/etc.), relevant to building a generic field-renderer instead of the app's current hardcoded dropdown lists.

Plus, cross-linked from `members.md`: `GET,POST,DELETE /buddyboss/v1/members/{user_id}/avatar` and `/cover` — confirmed to exist at the members level, not just xprofile.

### App — ✅ Confirmed (viewing only)
```
GET /buddyboss/v1/members/me           — AuthService.getCurrentUser()
GET /buddyboss/v1/members/{id}         — AuthService.getMember(id)
```
Used by `profile_page.dart`'s `loadUserData()`. Response fields read (🟡 High confidence, working code, not independently captured): `name`, `user_login`, `avatar_urls.full`/`.thumb`, `followers`, `following`, `total_post_count`, and notably a **hardcoded field-ID access**: `user["xprofile"]?["groups"]?["1"]?["fields"]?["31"]?["value"]?["raw"]` — used for the profile's subtitle/title text. This is the **only** real xprofile field ID reference left in the app (field `31`, group `1`) — unlabeled, not in a constants file, presumably discovered by trial at some point. No other field IDs exist anywhere in the codebase.

**No write/update endpoint is called anywhere in the app.** `updateProfileFields()` doesn't exist; nothing calls `POST /xprofile/update`, `POST /members/{id}/avatar`, or `POST /members/{id}/cover`.

## Models to create/change
- No dedicated `Profile`/`XProfile` model exists — `profile_page.dart` reads directly from the raw `response.data` map.
- `UserProfile` (`lib/models/user_profile_model.dart`) is dead-in-effect (writes go nowhere real) and should either be deleted once `EditProfilePage` is rebuilt against the real API, or explicitly reconnected — not left silently disconnected.
- A generic field-renderer keyed by `xprofile/types` would let the app support arbitrary/changing field configurations instead of hardcoded dropdown lists (`fields`/`levels`/`genders` arrays in `profile_setup.dart`) that would silently drift from whatever the website's admin actually configures.

## Functional Behavior

**Validation (confirmed from `profile_setup.dart`, still meaningful even though the save is broken):** username required + no-spaces check; field/level/gender/birthdate all required before submit is allowed. These client-side checks run correctly — it's specifically the persistence step after validation passes that's broken.

**State machine:** `ProfilePage` has an implicit `try/catch` around `loadUserData()` with `debugPrint(e.toString())` on failure — **no error state shown to the user at all** if the profile fetch fails; the screen just stays blank/stale. No loading indicator either — fields default to empty strings/placeholders until the future resolves, no `CircularProgressIndicator`.

**Avatar/cover:** view path works (reads `avatar_urls` from the real API response). Upload path (`change_profile_photo_page.dart`) is fully decorative — confirmed via grep, no picker/API code exists at all.

**Privacy:** no privacy controls exist anywhere in the app for profile fields — not investigated on the website side either (open question).

## Role / Account-Status Variations
Not tested.

## Undocumented / Plugin-Specific Behavior
`xprofile/repeater/*` — repeatable field groups, existence confirmed, structure/usage unconfirmed. `xprofile/types` — field type taxonomy, unexplored.

## Open Questions
- Real numeric field IDs for fieldOfWork/professionalLevel/gender/birthDate/bio/facebook/linkedin — **still unresolved**, same blocker as originally documented, since the resolution work described in the handoff doc isn't present in the current code. `GET /buddyboss/v1/xprofile/groups?fetch_fields=1` (documented, JWT-testable the same way Better Messages was) would resolve this directly — genuine capture/test gap, not fillable from existing evidence.
- What does field `31`/group `1` (the one ID actually used in `profile_page.dart`) represent? Presumably profession/title given how it's used, unconfirmed.
- Full response schema for `members/me` and `members/{id}` — 🟡 inferred from working code, not independently captured.
- Avatar/cover upload request shape (multipart fields, size limits) — unexplored.
- Is `onboarding1.dart`-`4.dart` (a separate flow reached from `splash1.dart`) meant to replace or complement `profile_setup.dart`? Not investigated — noted as a parallel-flow question similar to Groups' two-surfaces issue, not resolved here.

## Discrepancy Log

| # | Discrepancy | Previous assumption | New evidence | Classification |
|---|---|---|---|---|
| 1 | Onboarding xprofile save | `K54_PROJECT_HANDOFF.md`: rewritten this project — "removed all Firebase dependencies," calls `BuddyBossService().updateProfileFields()`, 3-step wizard | `lib/profile_setup.dart` (read directly): still imports `firebase_auth`/`firestore_service`, still uses `auth.currentUser` (always null), still a single-scroll form, `updateProfileFields()` doesn't exist anywhere in the codebase | **Documentation Drift** + **Confirmed Bug** — reachable from `face_id_verified.dart`/`touch_id_verified.dart`, not dead code |
| 2 | `XProfileFields` constants class | Documented as existing with placeholder `-1` IDs, blocking save | Doesn't exist anywhere in the codebase (grep confirms); `lib/utils/constants.dart` is empty | **Documentation Drift** |
| 3 | Edit Profile save | UI shows "Profile updated successfully" | Writes to a disconnected static in-memory class (`UserProfile`) that nothing else reads; zero network call | **Confirmed Bug** — not previously documented anywhere, found fresh this audit. Arguably worse than #1 since it actively tells the user it worked. |
| 4 | Change Profile Photo | UI presents a full "change photo" flow | No image picker, no API call, confirmed via grep — every handler is empty | **UI-only Placeholder** |
| 5 | Profile load error handling | N/A | `catch (e) { debugPrint(e.toString()); }` — failures are silent, no user-facing error state | **Missing Feature** (error handling, not a regression) |

## Parity Scorecard

**Capability list this score is computed from** (10 capabilities): view own profile, view another member's profile, edit basic fields (name/username/bio/etc.), edit custom xprofile fields (profession/level/gender/etc.), change avatar, change cover, field validation, privacy controls, repeater fields (multi-entry), search-by-profile-field.

- **Website Coverage:** 100% (baseline)
- **Flutter Coverage:** **2 of 10** (view own profile, view another member's profile — both via real API) = **20%**. Edit does not count despite extensive UI, since it persists nothing real.
- **Parity:** 20%
- **Confirmed Bugs:** 2 (onboarding silent-fail regression, Edit Profile's fake-success disconnected-model bug)
- **Missing Features:** 6 (real field-ID-based editing, avatar upload, cover upload, privacy controls, repeater fields, profile-field search)
- **Decorative UI:** 1 major surface (Change Profile Photo — entire screen), plus the "Change Photo" text button on `edit_profile_page.dart` itself
- **API Coverage:** 2 of 10 confirmed `xprofile` routes + 0 of the cross-linked `members/{id}/avatar`/`/cover` routes called by the app (view-only endpoints aren't even in the xprofile namespace — they're `members/me`/`members/{id}`) — effectively **0% of the xprofile write surface**, view path uses a different namespace entirely
- **Evidence Confidence:** ✅ 10 (profile_setup.dart's Firebase code confirmed by direct read, EditProfilePage's static-model bug confirmed by direct read, ChangeProfilePhotoPage's empty handlers confirmed by grep, `updateProfileFields`/`XProfileFields` absence confirmed by grep, viewing path confirmed working, field `31`/group `1` usage confirmed in code) / 🟡 1 (full `members/me` response schema, inferred not captured) / 🔴 4 (real field IDs, repeater structure, avatar/cover request shape, `onboarding1-4.dart`'s relationship to `profile_setup.dart`) → **(10 + 0.5)/15 ≈ 70%**
