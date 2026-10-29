---
name: qa-3000
description: Use when asked to QA or test an app feature or a bug fix end to end — a Jira story, epic or bug, a PR or a branch — "test <KEY>", "QA this PR", "full test cycle", "impact analysis and checklist", "are there tests for this", "file bugs from the test run", "протестируй <KEY>", "сделай QA", or when a teammate wants a QA report with screenshots. Works in any app repo; the app's facts come from its profile, .claude/qa-3000/profile.md in that repo.
---

# qa-3000

## Overview

One QA cycle for one feature of a Flutter app with a web build (another
stack needs its own driving notes in its profile).
**Documentation first, then evidence:** nothing
is tested before it is written down as a checklist and atomic cases, and
nothing goes to a shared system — Jira, TestRail, a pushed branch, a PR comment
— without an explicit "yes" (the report is published as a private Artifact,
which needs none). **A bug is filed only after it has been reproduced in the
app**, and a bug the user can see carries the screenshot that shows it.
Everything the web build can show, you test yourself; the rest becomes
precise steps for a human.

`<skill>` below is this skill's base directory, the path Claude Code gives
when the skill loads (it ships in the `qa-3000` plugin). Call its scripts by
that path from any worktree; every other path (`.claude/qa-3000/`,
`docs/qa/`, the specs, the e2e scripts) is in the app's repo.

## The app profile

Everything specific to one app lives in its profile,
`.claude/qa-3000/profile.md` in the app's repo, committed so the whole team
shares it (a local draft not yet committed: `docs/qa/profile.md`). Read the
profile before phase 0; this file and the references call its sections
"profile → <heading>": Repo and specs · Jira · TestRail · Stand · Accounts ·
Network and analytics · Language · E2E · Extra checks · Known — do not file.

Next to the profile, `.claude/qa-3000/nav.md` is the app's **navigation
map**: how to reach each screen, step by visible label, and the dead ends.
The plugin's hook puts it into your context before your first navigation
action; `<skill>/reference/navigation.md` has the rules. No map yet → the
first cycle starts one in the app repo's `docs/qa/nav/pending.md` from
`<skill>/templates/nav.md`.

A section that says "none" turns its step off: no e2e suite → no e2e
regression, and e2e gaps stay recommendations; no TestRail → the ★ cases stay
in the md; no web stand → the live run is native or goes to the Needs a human
table, decided at Stop 1.

A profile may also change one of this file's defaults — where the live run
happens (profile → Stand), when the e2e regression runs (profile → E2E) or
how Jira is written (profile → Jira) —
but only in a line that starts with **Overrides:** and gives the reason. Read
each one before phase 0 and name it in the Stop 1 round, with what it costs the
user (a device to keep connected, their hands for native taps, a skipped
regression), so they can turn it down. A profile that differs from this file
without that marker is wrong: follow this file and fix the profile at Stop 2.

No profile for this repo → draft one from `<skill>/templates/profile.md` into
`docs/qa/profile.md` of the app's repo (never into `<skill>`: a plugin
update replaces that folder). Fill it from what the repo shows (CLAUDE.md, the
SDK pin, e2e scripts, CI) and from what the APIs answer — Jira field ids from
the Atlassian MCP (`getJiraIssueTypeMetaWithFields` for the bug type), TestRail
projects and suites from `scripts/testrail.py projects` / `suites`. Put only
what is still missing into the Stop 1 round, as one grouped question. At Stop 2
offer it as a draft PR to the app's repo at `.claude/qa-3000/profile.md`.
Never guess a Jira field, a TestRail project or a stand.

## Report language

The report — `<KEY>.md`, `<KEY>-tests.md` and the HTML page — is written in
one language for the whole cycle: **English by default, another language when
the requester asks** — "report in Russian", "на русском", "auf Deutsch" in
the skill's arguments or in a Stop 1 answer, or profile → Language names a
report language for the team. Arguments that name it decide it without a
question; otherwise Stop 1 names the default in one line, so the user can
switch. In another language the headings, the status legend and the fixed
phrases come from `reference/test-docs.md` → Report language (Russian is
there ready; any other is translated from the English column the same way),
and the page gets the matching `<html lang>`. A delta keeps the language of
the cycle it continues unless the requester asks otherwise. The language of
the report never changes what goes to Jira, TestRail and the test cases: they
stay in English.

## The cycle

| # | Phase | Required output | Stops? |
|---|---|---|---|
| 0 | Scope | answers to the scope questions | **Stop 1** — one question round |
| 1 | Impact | `docs/qa/<KEY>.md` § Impact | no |
| 2 | Test documentation | checklist and 3–5 charters in `<KEY>.md` + `docs/qa/<KEY>-test-cases.md` with the ★ smoke set | **no — go straight to 3** |
| 3a | In the background: tests audit (subagent) · diff review (subagent) · e2e regression (background run) | `docs/qa/<KEY>-tests.md` · review candidates · regression result | no |
| 3b | Live run on the web stand, with the charters exploring beside it (all in parallel with 3a) | checklist statuses, `docs/qa/shots/<KEY>/NN-*.jpg`, charter findings | no |
| 3c | Sort every lead — from 3b, the charters, the review, the audit, a human — then reproduce each candidate | each defect: reproduced (where, ref) or not + its screenshots; each rejected lead with its reason | no |
| 3d | Bug only: a regression test for every case of the bug — the fix's own, or one you write | each test, red on the pre-fix ref and green on the fix; a local branch if you wrote any | no |
| 4 | Report | final `<KEY>.md` + HTML published as an Artifact → link | no |
| 5 | External writes: Jira bugs · TestRail smoke · e2e and regression-test branches · PR comments | keys, `C…` ids, draft PRs | **Stop 2** — before each write |
| 6 | Cleanup | processes, browsers and emulators the cycle started closed, worktrees removed, test users listed | no |

Formats of every file: `reference/test-docs.md`. There is no stop between
writing the documentation and testing it — do not ask for a review of the
cases.

## Phase 0 — scope

1. **Resolve the input.** Story (or each story of an epic) → its children,
   whether subtasks or linked FE / BE issues → PRs (dev panel, description,
   `gh pr list --search <KEY>`) → diff. PR → commits and the keys they cite.
   Branch → diff against `origin/main`. `<KEY>` is the story the teammate
   named; for a PR, the story its FE task belongs to (two stories: the form in
   profile → Repo and specs). Read the spec (profile → Repo and specs) and the
   acceptance criteria.
   A **bug** — a Bug ticket, or a PR that fixes one — also needs two refs: the
   fix (the fix PR's merge commit, or the open PR's head) and the pre-fix (that
   merge commit's first parent, or `git merge-base origin/<base> <head>` for an
   open PR — not the base branch's tip, which has moved on). The audit and
   phase 3d prove the regression test against both. **Rolling the fix back**
   means, in a worktree at the fix ref with nothing uncommitted: for each
   non-test path in `git diff --name-status <pre-fix> <fix>`, `M` or `D` →
   `git checkout <pre-fix> -- <path>`, `A` → `git rm -q <path>`; codegen again
   if those paths feed it. `git reset --hard HEAD` brings the fix back.
   `gh` not logged in but git can push over HTTPS: prefix calls with
   `GH_TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed -n 's/^password=//p')`.
   A token without `read:org` makes `gh pr edit` fail — change a PR with
   `gh api -X PATCH` instead (profile → Repo and specs).
2. **Look for prior QA** — files in `docs/qa/` whose *name* carries the key's
   number (a two-story file counts for both); bugs linked to the story and to
   each child (`issuetype = Bug AND (issue in linkedIssues(<story>) OR issue in linkedIssues(<child>))`)
   plus a text search for the area (profile → Jira);
   branches not yet merged (`git branch -r --no-merged origin/main | grep -iE 'e2e|<KEY>'`);
   TestRail sections whose name carries the key (profile → TestRail).
   If a cycle exists, run
   a **delta**: same key, same files, same Artifact URL (read it first; if you
   cannot edit it, publish a new page that links the old one). Re-run what is
   not ✅ plus whatever the diff since the last tested ref touches, reproduce
   the filed bugs again on the new ref (still there → a comment draft with a
   fresh screenshot; gone → say so), create the missing format parts, mark new
   checklist items "(delta)". A fixed bug is rechecked twice: on the original
   case and on one more instance with the same trait (a second category whose
   ids differ, another locale, another account type) — a fix can hold for the
   one case it was tested on. A flow that runs once per user (a celebration,
   a first purchase, onboarding) is rechecked with a new account: the old one
   cannot cross that line again. A gated feature also gets its negative
   rechecked on the new ref — a user without the entitlement, taken past the
   point the fix touched (e.g. to 100% of a category), sees nothing and sends
   no request for it. Accounts you provisioned earlier or handed to someone may
   have been used since: read each one's state from its own session (progress,
   entitlement) before using it. A defect the delta closes is closed everywhere
   the report still shows it — the summary tiles, the walked path, decisions,
   Needs a human, open questions — not only on its own line; the report then
   says what works now, and the old failure stays as one line of history. The
   prior report's known / not-filed block extends the profile's list.
3. **Note what already runs**, before you launch anything — the user's own
   emulator, simulator or browser tabs must outlive the cycle:
   ```bash
   { adb devices; xcrun simctl list devices booted; pgrep -lx 'Simulator|DeviceHub'
     pgrep -fl 'chrome-devtools-mcp/chrome-profile|ms-playwright'; } > <scratchpad>/baseline.txt 2>&1
   ```
   If the chrome-devtools browser is in that list, add its `list_pages`: pages
   mean it is this session's (or the user's through it); `The browser is
   already running for …/chrome-profile` means another session holds this
   machine's one browser — that goes into the round below. With no such
   browser running, do not call `list_pages` now: it would start one before
   the baseline is written, and phase 6 would then take it for someone
   else's. If you have a locale-pinned browser helper (a `locale-browser`
   skill or the like), add its status too. Phase 6 closes only what is not in
   this file.
4. **Ask once** — one question round, ≤ 4 questions: scope (merged only, or
   branches too); spec vs story acceptance criteria when they disagree (default:
   test what shipped, list each divergence); platform (default: the web stand,
   in both the desktop and the mobile view, + a hand-over table, or what the
   profile overrides it with — the two views are not a question); the report
   language when the arguments do not name it (default English — see Report
   language); accounts and access — a test user, one more per charter
   (up to five; `reference/charters.md` → Accounts) and the e2e regression
   may each cost a test-card subscription (profile → Accounts, E2E); the
   chrome-devtools browser when step 3 found another session holding it —
   it blocks the live run and the charters alike until the user frees it;
   later
   steps need a Jira login in the chrome-devtools browser, `gh`, the TestRail
   credentials `scripts/testrail.py` reads, and the secrets file the profile
   names — when profile → Jira turns on the dev-process-toolkit module, also
   the two toolkit checks of `<skill>/reference/jira-dev-process-toolkit.md`
   → Before Stop 1, whose answers go into this round. Running as a
   subagent: return the questions — and later the Stop 2 drafts — to the caller
   and stop; Stop 2 writes happen only in the main session after the user's
   "yes". After the answers, no further questions until Stop 2.

## Phase 1 — impact

`§ Impact`: what changes for the user; the ticket breakdown with statuses; the
acceptance criteria that no longer match what shipped; verification numbers
(filled in after phase 3).

## Phase 2 — test documentation

Checklist (~25 lines, each naming the failure it hunts) and atomic cases (one
assertion, ≤ 3 steps, stable ids `<PREFIX>-NN`, ★ on the release-blocking
smoke set). Cover: happy path; for a gated feature, entitlement on / off and
its boundary (a user without it, another user after logout → login in the same
tab, another pack's content with this user's session); empty / one / many;
loading and error states; offline; slow network; back navigation; locales —
one representative non-English locale unless the behaviour differs per locale;
analytics events — in every vendor the profile names, by the vendor's answer, not only by the request; errors on open — the console and the error reporter on every screen, sheet and dialog the change adds, even when it looks right (`reference/live-web.md` → Errors on open); and what the change touched outside its own screen. Add the
profile's extra checks when the change is of their kind, even if no criterion
names them (profile → Extra checks). A case the stage data cannot reach is
kept and marked N/A with the reason.

**Both views, always.** Every checklist item and every case with something on
screen is checked in the desktop view **and** in the mobile view
(`reference/live-web.md` → Desktop and mobile view) — a change that touched
only one layout still gets both, because the other one is where it breaks
unnoticed. A case for something only one view shows says so in its title,
and in the other view checks what stands there instead — the element is
absent, or its counterpart for that view is shown and works; a check with nothing on screen (an
analytics payload, a request) runs once and says which view.

Then the **charters**: three to five, each one area, one posture and one
sentence, chosen where the change is and where the checklist is thin
(`reference/charters.md` → Write them). The checklist tests what you
thought of; the charters hunt for what you did not.

## Phase 3 — background tracks and the live run, then reproduce

**3a. Three background tracks**, all started as soon as the documentation
exists. The two that build — the audit and the e2e regression — each get their
own worktree: codegen, the test run and the e2e suite collide with a running
app and with each other. The review only reads git.

- **Tests audit** — Agent tool, `run_in_background: true`, brief =
  `<skill>/prompts/tests-audit.md` with the slots filled: its own worktree, the
  absolute output path, the unmerged e2e branches from phase 0, the profile's
  build and e2e facts. It maps every case and criterion to a unit / widget / e2e
  test or a gap, judges the tests the change added, runs the repo's tests and
  analyzer, and writes `docs/qa/<KEY>-tests.md`. You do not audit yourself;
  read its file when it reports back. Payloads you capture during the live run:
  save them under the scratchpad and send their paths to the agent
  (SendMessage). For a bug, fill the brief's bug slots too — the key, both
  refs, the symptom, the ticket's steps and expected result, and where its
  spec lives (profile → spec repositories): the audit then proves, bug case
  by bug case, whether the fix ships a test that fails on the pre-fix ref
  (§ Regression test).
- **Diff review** — Agent tool, `run_in_background: true`, brief =
  `<skill>/prompts/diff-review.md` with the slots filled. It replies with at
  most 15 checked candidates (`R-NN`, what the user would see, how to show it on
  the web stand). They are leads for 3c, not results: none goes into the report
  or Jira until you reproduce it.
- **E2E regression** — unless profile → E2E overrides when it runs, the app's
  whole e2e suite once, as a background Bash run
  in its own worktree `<scratchpad>/wt-e2e` at the ref under test, prepared and
  started as profile → E2E says. Do not edit the runner while it runs (bash
  reads the script as it goes). Red → read the log first — the first failure,
  its step trace, what the network answered (the app's e2e skill → Failure
  triage) — then decide whether it is this change, a flake or the environment.
  The result goes into § Verification.

**3b. Live run** — first dispatch the charters, all in one message
(`reference/charters.md` → Dispatch): each explores in an isolated context
of your browser and an account of its own while you work. Only on a
deployed stand: on a local `flutter run` debug build (a branch cycle) the
charters' tabs coming and going wedge DWDS under your own run — skip them
there and say so in the report.
`<skill>/reference/live-web.md` has the driver, the network
harness (`<skill>/scripts/net.js`) and the gotchas; the stand and the accounts
come from the profile. Walk the checklist in order, in the desktop view and
then in the mobile view; after each item write its status per view
(`desktop ✅ · mobile ❌ …`) and one result line into `<KEY>.md`, and save a
screenshot per view (`NN-what-desktop.jpg`, `NN-what-mobile.jpg`). An item
with one view unchecked is not done. Before concluding "does not work", run a
control on something known to work. Reach each screen from the navigation map, tapping by label and
marking the way with `nav_mark.sh` (`<skill>/reference/navigation.md`); search
only for what the map lacks.

**3c. Sort every lead, then reproduce each candidate** — the leads are the
ones you hit in 3b, the charters' findings (read each reply as it arrives;
before the sort is final and the report is written every charter has
replied — one past its budget by five minutes is stopped with TaskStop and
recorded as "no reply"),
the diff-review candidates, gaps the audit or your code reading suggests, a
red e2e scenario, and the ones a human reported:

0. Sort them before you write a single step (`reference/charters.md` → Merge
   and sort): merge duplicates; a tool artifact, an environment limit, a
   design decision or a data gap is rejected with its reason; only the
   candidates go on. When an environment cause shows a wrong handling on
   screen — a raw error, a dead end — the handling is a candidate: force the
   same failure on web here; only one web cannot produce becomes a line
   under the report's production risks.
1. Write the steps first, as the ticket will say them, in English: precondition,
   numbered steps from a user's entry point (a UI label quoted as the app shows
   it, its English meaning in parentheses — `reference/jira.md`), actual,
   expected. A backend defect's steps carry the exact request and the wrong
   answer, with the token as a placeholder.
2. Replay exactly those steps from a fresh state — new page load or new login,
   no leftovers from the run that found it — in both views; the ticket names
   the view it fails in ("mobile view only", "both views"). Force the path
   when it needs a condition: `net.js` for offline / delay, a missing id for a 404, root
   font-size for large text, a stubbed browser API
   (`navigator.clipboard.writeText = () => Promise.reject(new Error('qa'))`)
   for a failure branch. A forced condition still counts as reproduced on web;
   the precondition names it ("Clipboard write forced to fail from DevTools").
   Before calling it not reproduced, try at least the plain path and the forced
   condition the code points at (timing, order, failure), each with a control.
3. Take the screenshots **in this replay** — anything on screen counts as
   visible, including feedback that should appear and does not (no toast, no
   error). A pair when a condition triggers it: the same kind of screen in its
   normal state (another item online, the success toast without the stub) and
   the defect. The console lines as an image when the symptom is an exception
   or a log line (`reference/live-web.md` → Console). Evidence that is text — an
   analytics payload, a response body — is copied verbatim instead. A defect
   that unfolds in time — a flash, a double request, a race, text that bounces
   back, a button with no busy state — also gets a **video of the same replay**
   with the requests or events that prove it logged on screen
   (`reference/live-web.md` → Video): a still frame cannot show it. A static
   layout, an error screen or a payload needs no video.
4. Record the result next to the defect in `<KEY>.md`: **reproduced on web ·
   <desktop | mobile | both views> @ `<ref>`**, **reproduced by <person> on <device>** (their photo or video is
   the first attachment), or **not reproduced** — with what you tried.

A reproduced defect is filed without a test: the developer who takes the bug
writes its regression test with the fix — with the dev-process-toolkit module
on, from the spec's `Regression:` criterion
(`reference/jira-dev-process-toolkit.md` → The bug's spec in the repository). This is about a bug
this cycle files only — e2e gaps (phase 5 → Autotests) and a bug fix under
test (3d) still get their tests.

A defect that is not reproduced is not drafted as a bug. When only a device or
an access you lack could show it (native state, disk cache, safe area), it goes
to the Needs a human table with the device and the steps. When you tried it on
web and it did not happen, it goes to open questions for the developer, marked
"by code, not reproduced — tried: …".

**3d. Regression test — bug cycles only.** A bug counts as fixed only when an
automated test fails on the pre-fix ref and passes on the fix: the app behaving
today proves the fix, the test is what stops the bug from coming back — for
every bug case (each AC of the bug's spec, or each condition of its ticket,
as the audit lists them), not only the one the fix's test happens to drive.
Take the verdicts from the audit's § Regression test, one per bug case:

- **catches the bug** — name the test in § Verification; nothing to write.
- **missing**, **cannot fail** or **does not compile on pre-fix** — write a
  test for that bug case yourself, whatever its layer. Steps 1–5 run once per
  such bug case, in the same worktree; step 6 once, for all of them:
  1. A worktree `<scratchpad>/wt-regress` detached at the fix ref itself — not
     `origin/main`: later commits there would turn the rollback into something
     else — with the codegen profile → Repo and specs names. Created for the
     first bug case, reused for the rest.
  2. The lowest layer that reproduces it: unit when the failure is in a use
     case, repository or cubit; widget when the user sees it on one screen; e2e
     only when only the journey shows it (profile → E2E layer rule, the app's
     e2e skill). Follow the conventions of the test files next to it.
  3. Drive the condition the ticket names — the 404, the null, the throw, the
     order — and assert what the user loses: the screen it stays on, the
     navigation that never happens, the wrong value. Not that the fix's new code
     ran.
  4. Use only API that exists on both refs, so the test compiles on the pre-fix
     code.
  5. Commit the test locally, then prove it: green as is; roll the fix back
     (phase 0) and run it — red, failing the way the bug looks, at the
     assertion that encodes the bug (a finder timeout or a compile error
     before it is not red: the test is wrong); `git reset --hard HEAD`.
     Green on the rolled-back code too → it catches nothing; rewrite it.
  6. Move them onto the branch the PR will come from: `git switch -c
     test/<KEY>-regression origin/main` (or the app's CLAUDE.md branch
     template), `git cherry-pick` every test commit, run the touched test
     files and the analyzer there — green on today's main. The push and the
     draft PR wait for Stop 2 (phase 5 → Autotests).

  § Verification gets one row per bug case: the test (`file:line`), red on
  `<pre-fix>` with its first error line, green on `<fix>`, and whether this
  cycle wrote it.

## Phase 4 — report

Finish `<KEY>.md`: statuses, defects, "known — not filed", the charters,
the rejected leads by reason, the production risks, a **Needs a human**
table, an **owners** table for decisions and access (item · who), open
questions.

- **Curate, never paste.** Agent output — review candidates, charter
  findings, audit tables, logs — is material, not the report. Defects by
  priority (`reference/jira.md` → Priority) — this is the one layout the md,
  the HTML and the mistakes table below refer to: Highest and High in detail
  (what the user sees, why with a file, how it was reproduced, screenshots);
  Medium one line each with its key and a link to its
  screenshot; Low and Lowest one line each too. Only reproduced defects are
  listed as defects; the rest are open questions.
- **Charters** — one row each: posture, area, how it ended, findings (kept /
  rejected), what it did not reach.
- **Rejected leads** — grouped by bucket (tool artifact, environment, design,
  data), one line each with the reason — a candidate that did not reproduce
  is an open question, not a rejected lead: the reader sees
  what was looked at and why it is not a bug.
- **Production risks (not verified)** — an environment lead the stage cannot
  show for real but the app would handle badly in production too.
- **Needs a human** rows (the columns in `reference/test-docs.md`): the check ·
  why web cannot show it · device, setting and build · ≤ 3 steps · **where to
  look** — the screen and element, or the request and field (profile →
  Accounts names where entitlements show). Before handing a check over,
  confirm that build contains the change: find the first build with the merge
  commit and compare it with the build the person has (profile → Stand). Older
  → say so and wait for a deploy instead of sending the check.
- **Results a person reports** go into the checklist at the item they close:
  `[x] ✅` or `[x] ❌` plus "checked by hand — <who>, <date>" and what they saw.

Build
`docs/qa/<KEY>.html` from `<skill>/templates/report.html`, publish it with the
Artifact tool (screenshots via `files`; the tool takes files only from the
working directory or the scratchpad, so copy the HTML and its shots to
`<scratchpad>/report/` and publish with `root` there), and reply with a short summary, the
link and what needs the human. Artifacts are private — say the owner has to
share it. No Artifact tool in the session → keep the page at
`docs/qa/<KEY>.html` with its shots beside it and give its path instead.
Credentials go to the chat, never into these files.

## Phase 5 — external writes, each after a "yes"

- **Jira bugs** — only reproduced defects. Drafts in chat first, in English as
  they will be filed: a table of priority with its reason
  (`reference/jira.md` → Priority) · summary · story · reproduced (where,
  ref) · attachments (file names, or "payload in steps" for text evidence),
  plus the first sentence of *what's wrong* each, checked against the prior-QA
  bugs and the known list. A visible defect without a screenshot is not a
  finished draft. On
  "yes", file them as `<skill>/reference/jira.md` says with the fields from
  profile → Jira — with the dev-process-toolkit module on, as
  `<skill>/reference/jira-dev-process-toolkit.md` says, which also decides
  who creates the ticket and, when the profile asks, adds each bug's spec and
  its PR. A defect
  in a product PR not yet merged gets no ticket of its own when the user
  prefers a PR comment. Verify, write the keys (and the spec PRs) into the md
  and the HTML — with any priority changed at Stop 2, the defect moved to its
  group — and republish. Re-check results on existing bugs are comments — drafts first
  too, and with the toolkit module after its ownership step. No
  transitions and no story comments unless asked.
- **TestRail** — the ★ cases only, into `<Feature> (<KEY>)` under the feature's
  section of the app's project and suite (profile → TestRail); payload and push
  in `<skill>/reference/test-docs.md`.
- **Autotests** — the e2e gaps from `<KEY>-tests.md`: propose the list;
  on "yes" continue the area's unmerged e2e branch and PR if there is one,
  otherwise a worktree on `test/<KEY>-<slug>` (or the app's CLAUDE.md branch
  template) from `origin/main`; write them by the app's e2e skill (profile → E2E), run only
  the changed scenario files, open a draft PR (`gh pr create --draft`). Its
  description says what changes, why and how it was verified — no "not in this
  PR" or future-work block. After the push, only an Impact comment (draft
  first): a PR with tests only gets no QA test plan. The regression tests from
  3d go the same way whatever their layer — one draft PR for the bug unless
  the area's open e2e PR fits them; the description names the bug and, per
  bug case, the test that catches it, red on the pre-fix ref, green on the fix. Other unit and widget gaps stay
  recommendations for the developer.
- **PR comments** — for a product PR that is still open: the Impact and QA test
  plan comments the app's CLAUDE.md describes (none described: Impact = what
  changes for the user, why, how it was verified; QA test plan = the ★ cases as
  a checklist), as drafts first.
- **The navigation map** — `docs/qa/nav/pending.md` merged into
  `.claude/qa-3000/nav.md` as a draft PR to the app's repo, draft first; empty
  `pending.md` once it is merged.
- **The profile** — a new one (`docs/qa/profile.md` → `.claude/qa-3000/profile.md`),
  or a line for Known — do not file after the team rules a finding
  "by design": a draft PR to the app's repo, draft first. The map and the
  profile may share one PR.

## Phase 6 — cleanup

When the cycle is over — the report is out and the Stop 2 writes are done or
declined — close everything the cycle started; what `<scratchpad>/baseline.txt`
(phase 0) lists stays as it was:

- **processes**: a local app run, the e2e run, `adb logcat` and `screenrecord`
  captures, a `screencast_start` still recording, the Proxyman rules and
  network conditions you added;
- **browsers**: chrome-devtools `close_page` for every tab you opened. The
  last tab cannot be closed, so when the browser itself is not in the baseline,
  quit it: `pkill -f 'chrome-devtools-mcp/chrome-profile'`. Only one session
  can hold that profile, so a browser missing from the baseline is this
  session's; the MCP launches it again at its next call, and the profile keeps
  the Jira login. A browser that is in the baseline belongs to the user or to
  another session — leave it running. Playwright MCP → `browser_close`;
  `locale-browser down` for each locale you started; a Chromium the e2e runner
  left behind (`pgrep -fl ms-playwright`, not in the baseline) → `kill` it;
  a charter closes its own page; one still in `list_pages` with
  `isolatedContext=<slug>` after every charter replied → `close_page` it.
  Close nothing in the browser while a charter still runs;
- **emulators and simulators** you booted — for the live run, the e2e run or a
  replay: `adb -s emulator-<port> emu kill`; `xcrun simctl shutdown <udid>`,
  then quit the Simulator app (DeviceHub on Xcode 27) unless the baseline has
  it. A physical device is the user's — leave it as it is;
- `git worktree remove` every worktree this cycle created — yours
  (`<scratchpad>/wt`, `wt-e2e`, every `wt-spec-<repo>` and the e2e and
  `wt-regress` ones after their tests are on their branches and pushed) and
  the audit subagent's (`wt-audit`); `git worktree list`, leave the rest. A
  `wt-spec-<repo>` left with drafts nobody said "yes" to holds untracked
  files, so it needs `--force`;
- list the test users you created (email only) in the chat — the charters'
  too — and say which the human still needs for the Needs a human checks;
- update the navigation map: each successful search becomes a route, each dead
  end a row, a failed route `broken` with its replacement, a route not walked
  for 3 releases `stale` — into `docs/qa/nav/pending.md`, with the
  `nav_report.py` table in § Verification (`<skill>/reference/navigation.md`);
- keep `docs/qa/`: it is the record, and it is not in git.

Then run the phase 0 commands again and compare the output with the baseline.
Anything of yours still up — a kill the permission check declined, an emulator
that would not stop — goes into the reply by name, so the user can close it.

If Stop 2 answers are still pending, keep only what those writes need — the
chrome-devtools browser with the Jira tab, the e2e worktree — close the rest
now (emulators, simulators, the local app run), and name what stays up.
Running as a subagent: clean up the same way before you return the Stop 2
drafts, and name what stays up for the main session.

## Common mistakes

| Mistake | Instead |
|---|---|
| Testing first, writing cases afterwards (or never) | The cases are the test plan: write them, then test them |
| Asking the user to approve the cases before testing | Only Stop 1 and Stop 2 exist |
| Guessing a Jira field, a TestRail project or a stand | Take it from the profile; no profile → the template, and ask at Stop 1 |
| Auditing the tests inline and burying the result in the report | Background subagent, its own file `<KEY>-tests.md` |
| Checking a feature in one view only (desktop, or only the mobile width) | Every on-screen item in both views, a status and a screenshot per view (`reference/live-web.md` → Desktop and mobile view) |
| "Mobile view" by `resize_page` alone | Width, touch and a mobile user agent together, then reload — the app may branch on the platform, not on the width |
| Planning simulators and emulators by default | The web stand; device-only checks go to the Needs a human table unless the user asked for native or the profile's **Overrides:** line, named at Stop 1, says otherwise |
| Pushing every case to TestRail, or asking where they go | The md keeps the full set; the ★ cases go to the rule's subsection, confirmed at Stop 2 |
| Running the e2e suite inside the tests audit, or in the worktree a local app runs from | The audit reads the scenarios; the regression is its own background run in its own worktree |
| Pasting review or audit output into the report | Curate by priority as Phase 4 lays it out; unreproduced leads are open questions |
| Handing a check to a person on a build without the change | Check the build number first (profile → Stand) |
| Leaving a local app run, the e2e run, a browser, an emulator, a simulator or worktrees behind | Phase 6, checked against the phase 0 baseline |
| Shutting down an emulator, a simulator or a browser the user already had running | Close only what `baseline.txt` does not list |
| Recommending e2e tests instead of writing them | Write them after the "yes", on the area's e2e branch and a draft PR |
| Calling a bug fixed because the app behaves now | Phase 3d: a test red on the pre-fix ref and green on the fix — the fix's own, or one you write |
| A regression test shown only green | Put the fix's production files back to the pre-fix ref and watch it fail the way the bug looks |
| Counting a scenario on an unmerged branch as coverage | "gap on main — pending on `<branch>`" |
| "Not tappable" from a synthetic `PointerEvent` | Those never reach Flutter — use a control click first |
| Reloading the page to "go offline" | Wipes in-memory caches — use `window.__qa.block` |
| Re-filing a known decision | Check profile → Known — do not file, the prior report and the story's linked bugs |
| Toolkit module on: a create without the toolkit's decision (`createJiraIssue` alone, or REST) | `create_idempotency_probe.ts decide` first, or the user files it by hand (`reference/jira-dev-process-toolkit.md`); REST slips past the hook, not past the rule |
| Toolkit module on: a comment, an edit or an attachment on a ticket not created in this session, straight away | The ownership step first (`reference/jira-dev-process-toolkit.md`); a foreign ticket's draft goes to the user |
| Filing a finding from code reading, "reproduced by code" | Force the path on the live app (3c); not reproduced → Needs a human / open question, not a bug |
| Steps in the ticket written from memory | Replay the drafted steps from a fresh state; if they do not reproduce it, the steps are wrong |
| Steps in another language: a German or Russian label with no English, or a sentence left in the app's or the draft's language | Every line English; a label as the app shows it, then its English meaning in parentheses (`"Beenden" (Quit)`) — `reference/jira.md` |
| A visible bug filed with no screenshot, or with one from the first sighting | Screenshots from the 3c replay, of what the user sees — a pair when a condition triggers it |
| A timing defect (double tap, flash, race, a send that bounces back) filed with screenshots or a payload only | A video of the 3c replay with an on-screen log of the taps and requests |
| Screenshots on an analytics or payload bug | The payload goes into Steps verbatim; a picture adds nothing |
| Analytics checked in one vendor, or by the request alone | Every vendor the profile names, and each one's response — a 400 means the event never lands |
| "Works on screen" taken as clean while the console or Sentry logs an error on open | Read both on every new screen; an unhandled error is a defect even when the user sees nothing — and an e2e scenario that catches it to stay green is a finding, not a fix |
| Searching a screen by screenshots and coordinates | The navigation map first, then tap by label (`tap_text_android.sh`, `tap_text_ios.sh`, web semantics `find`) |
| Finishing a cycle with what you learned about navigation only in your head | Phase 6: new routes, dead ends and broken routes into `docs/qa/nav/pending.md` |
| Testing only the checklist | Three to five charters explore beside the live run (`reference/charters.md`) |
| Charters sharing a page, a cookie jar or an account | Each in its own isolated context (`new_page isolatedContext`), its `pageId` on every call, its own account |
| Taking a charter's finding as a result, or reproducing leads unsorted | Sort first — artifact, environment, design, data, candidate — then reproduce only candidates (3c) |
| Dropping a rejected lead silently | The report's rejected leads by reason; an environment lead that would hurt in production stays a risk |
| A regression test "red" on a finder timeout, a boot failure or a compile error | Red only at the assertion that encodes the bug — anything earlier is a wrong test (3d) |
| Writing a test for a bug this cycle files | Not this cycle's: the developer writes it with the fix (with the toolkit module, from the spec's `Regression:` criterion). A bug fix under test is another matter (3d) |
