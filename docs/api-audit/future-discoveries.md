# Future Discoveries

Namespaces, plugins, and leads found while auditing the core priority features, deliberately kept separate so they don't interrupt or expand the current audit order (Activity Feed → Members → Profile → Friends → Groups → Notifications → Courses, then a dedicated K54 AI Assistant audit). Nothing here is scheduled yet — each entry just has a pointer to where the raw evidence already lives, so it isn't lost.

**Not here:** K54 AI Assistant (`k54-ai/v1`) — confirmed to be a first-class, custom K54 feature, not a peripheral discovery. It has its own row in `feature-inventory.md` and a dedicated audit scheduled after the 7 core features complete.

## Better Messages' official mobile-app integration (`better-messages/v1/app/*`)
`login`, `savePushToken`, `getSettings`, `syncScripts` — a likely purpose-built mobile integration path, possibly superseding both the plain-REST and WebSocket approaches for messaging real-time. Full detail: `messaging-better-messages.md`, `implementation-blueprint.md`. Relevant if/when the messaging blueprint moves toward Stage B/C — not part of the current 7-feature core audit.

## Live Streaming / VOD / PPV (WPStream — `wpstream/v1`)
Confirmed active plugin, 2 REST routes (`playback-session-verify`), "Free-To-View Live Channels"/"Free-To-View VODs" nav items in wp-admin. Zero app coverage, not in the original priority list. Full detail: `plugin-inventory.md`, `rest-route-index.md`, `dependency-map.md`. Needs a product decision on whether it's in scope at all before any audit work is justified.

## Events (The Events Calendar — `tec/*`, `tribe/*`)
Confirmed active, two coexisting REST API generations (legacy `tribe/events`/`tribe/event-aggregator`/`tribe/views`, newer `tec/v1`/`tec/v2/onboarding`). Zero app coverage, not in the original priority list. Full detail: `plugin-inventory.md`, `rest-route-index.md`, `dependency-map.md`. Same status as Live Streaming — needs a scoping decision, not yet auditable as a prioritized feature.

## Second social-login system (`bb-social-login/v1`)
Separate from Nextend Social Login, includes a Microsoft OAuth redirect route. Whether it's independent or bridges into Nextend is unconfirmed. Relevant to Authentication's existing social-login gap, but not itself a new prioritized feature — folded into the Auth row in `feature-inventory.md` rather than tracked separately here.

## LearnPress's separate token-auth system
`learnpress/v1/token`, `/token/register`, `/token/validate` — distinct from the site-wide JWT. Directly relevant to the Courses audit (last in the current priority order) — will be investigated when that audit happens, not before. Full detail: `rest-route-index.md`.

## Unexplained `mcp` / `mcp/mcp-adapter-default-server` namespaces
Purpose not investigated — possibly an AI-tooling integration bundled with a Hostinger AI plugin. Noted for awareness only; not pursued unless it becomes relevant to something in scope.
