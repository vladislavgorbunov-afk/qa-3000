# Brief for the diff-review subagent

Dispatch with the Agent tool, `run_in_background: true`, together with the
tests audit — it runs while you test the app live. Its candidates feed phase
3c; none of them reaches the report or Jira until you reproduce it. Fill the
`<…>` slots; send everything below the line as the prompt.

---

You review one change in `<app>` for defects a user or the business would notice.
Read-only, in `<repo path>` without a worktree: `git diff <base>..<head>`,
and every file it touches in full **at `<head>`** — `git show <head>:<path>`,
not the working tree, which may be on another branch. Stories: `<KEY…>`; acceptance criteria:
`<file or pasted list>`. Do not change anything, do not run the app or tests,
do not file anything.

Already known — do not report again: `<the app profile's "Known — do not file" list,
the prior report's not-filed block, the story's linked bugs>`.

## Where to look

Hunt in this order; skip what the diff does not touch.

1. **Entitlement and state across users** — what decides who sees the feature,
   what survives logout → login, caches keyed without the user.
2. **Caching and offline** — TTLs, what is resolved before the cache is read,
   what happens when one request of a chain fails.
3. **Lifecycle races** — emit after `close`, a response arriving after the
   screen left, double taps, awaits without `mounted` checks.
4. **Error and empty states** — what the screen shows on 4xx / 5xx / timeout /
   `null` in a payload: zeros, stale data, a dead end without a way out.
5. **Navigation** — Back, `pop` without `canPop`, deep links, routes left
   registered for users who should not reach them.
6. **Analytics** — every event the change adds, removes or edits, against the
   same event on the last release tag (`git show <tag>:<file>`): a kept name
   with changed properties breaks dashboards silently.
7. **Copy and locales** — hardcoded strings, missing plural forms, casing
   applied to content, overflow with long translations or large text.
8. **Layout on devices** — safe area, `isScrollControlled` sheets, overscroll,
   fixed heights that break with a large system font.

## Check every candidate before you report it

Try to refute it: read the callers, the guard two frames up, shared packages at
the version the app pins (`<app profile → Repo and specs>`). Drop it if the refutation holds. Keep only
what survives.

## Reply — nothing else

At most 15 candidates, most severe first, one block each:

```
R-01 · High · lib/…/cdn_content_client.dart:68
What the user sees: every library screen shows the error screen after 5 min offline, though the content is cached for 7 days.
Why: the version (TTL 5 min) is fetched before the content cache is read.
How to show it on the web stand: open a list, cut the network (net.js block), wait past 5 min, open it again.
Confidence: high — read the full call chain.
```

No preamble, no summary, no statistics about how many you looked at.
