# qa-3000

A Claude Code skill that runs one full QA cycle for a feature or a bug fix:
from a Jira story, a PR or a branch to a published report with screenshots,
reproduced Jira bugs and the missing tests.

Documentation comes first, evidence second: nothing is tested before it is
written down as a checklist and atomic cases, no bug is filed before it has
been reproduced in the app, and nothing goes to Jira, TestRail or GitHub
without your explicit "yes".

## What one cycle does

| # | Phase | Output |
|---|---|---|
| 0 | Scope | One round of questions (Stop 1) |
| 1 | Impact | What changes for the user, ticket breakdown, ACs vs what shipped |
| 2 | Test documentation | ~25-item checklist, atomic test cases with a ★ smoke set, 3–5 exploratory charters |
| 3a | Background tracks | Tests audit and diff review (subagents), the whole e2e suite as a regression run |
| 3b | Live run | The checklist on the web stand, in the desktop **and** the mobile view, screenshots per view; charters explore in parallel, each in its own isolated browser context and account |
| 3c | Reproduce | Every lead sorted (tool artefact, environment, design, data, candidate), each candidate replayed from a fresh state with screenshots or video |
| 3d | Regression test (bug fixes) | A test per bug case, proven red on the pre-fix ref and green on the fix |
| 4 | Report | `docs/qa/<KEY>.md` plus an HTML report published as a private Artifact |
| 5 | External writes (Stop 2) | Jira bugs, TestRail smoke cases, e2e and regression-test draft PRs, PR comments — each after a "yes" |
| 6 | Cleanup | Closes only the browsers, emulators, processes and worktrees the cycle started |

## Install

```text
/plugin marketplace add vladislavgorbunov-afk/qa-3000
/plugin install qa-3000@qa-3000
```

Then, in an app's repo: `/qa-3000 APP-123`, or just ask "test APP-123",
"QA this PR", "full test cycle for this branch".

## Set up an app: the profile

Everything specific to one app lives in its repo, committed, so the whole
team shares it:

- `.claude/qa-3000/profile.md` — repo and specs, Jira fields and components,
  TestRail project, stands, test accounts, network and analytics, language,
  e2e, extra checks, and the "known — do not file" list. Start from
  [`templates/profile.md`](plugins/qa-3000/skills/qa-3000/templates/profile.md).
- `.claude/qa-3000/nav.md` — the navigation map: how to reach each screen by
  visible labels, and the dead ends. Start from
  [`templates/nav.md`](plugins/qa-3000/skills/qa-3000/templates/nav.md).
  The plugin's hook puts it into Claude's context before the first navigation
  action of a session.

No profile yet? The first cycle drafts one into `docs/qa/profile.md` from what
the repo and the APIs show, asks only for what is missing, and offers it as a
PR at the end. A section marked "none" turns its step off (no TestRail, no
e2e suite, no web stand).

## Requirements

The skill is built for **Flutter apps with a web build**; the live run drives
Flutter's semantics tree. Another stack needs its own driving notes in the
profile.

- **chrome-devtools MCP** (1.9+, with `pageId` support) — the live run and the
  charters. Playwright works as a fallback.
- **Atlassian MCP** — reading stories and filing bugs; without it, REST from a
  logged-in Jira tab.
- **`gh`** — PRs, diffs and draft PRs.
- **TestRail** (optional) — `scripts/testrail.py` reads `TESTRAIL_URL`,
  `TESTRAIL_USER` and `TESTRAIL_API_KEY`, or a JSON file named by
  `TESTRAIL_CONFIG`.
- **Dart MCP** (optional) — driving a local debug build; `scripts/drive.dart`
  is the fallback.
- Native helpers (optional): `adb` for `tap_text_android.sh`,
  [AXe](https://github.com/cameroncooke/AXe) for `tap_text_ios.sh`, `ffmpeg`
  for bug videos.
- [dev-process-toolkit](https://github.com/nesquikm/dev-process-toolkit)
  (optional) — when several repositories share one Jira project guarded by its
  hooks, the profile turns on the module in
  `reference/jira-dev-process-toolkit.md`: bugs are filed through the
  toolkit's decisions, and each bug gets its spec in the repository.

## Report language

English by default. Ask for another one in the arguments ("report in
Russian", "на русском") or set the team's language in the profile; a Russian
translation of the report's fixed phrases ships with the skill. Jira bugs,
TestRail and test cases always stay in English.

## Layout

```text
plugins/qa-3000/
  hooks/hooks.json            navigation-map hook
  skills/qa-3000/
    SKILL.md                  the cycle
    reference/                live run, charters, Jira, test docs, navigation
    prompts/                  briefs for the audit, review and charter subagents
    scripts/                  network harness, driver, tap-by-label, nav metrics, TestRail
    templates/                profile, navigation map, HTML report
```

## License

MIT
