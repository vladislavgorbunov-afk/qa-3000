# Brief for the tests-audit subagent

Dispatch with the Agent tool, `run_in_background: true`, right after the test
documentation is written — it runs while you test the app live. Fill the
`<…>` slots; send everything below the line as the prompt.

---

You audit the automated tests of one feature of `<app>`. Create your own worktree
(`git worktree add --detach <scratchpad>/wt-audit <ref>`) — never use the one
a running app is using. SDK, version wrapper and codegen: `<app profile →
Repo and specs>`. Change under test: `<PR / commit range / branch>`. Stories:
`<KEY…>`. Unmerged e2e branches for this area: `<branches, or none>`.

Inputs:
- Acceptance criteria: `<file or pasted list>`
- Manual test cases: `docs/qa/<KEY>-test-cases.md` (ids `<PREFIX>-NN`)
- Real payload samples, if any: `<paths>` — fixtures are compared against
  these; more may arrive by message while you work
- Bug cycles only: the bug key `<KEY>`, fix ref `<sha>`, pre-fix ref
  `<sha>`, the symptom `<one line from the ticket: the condition and what the
  user sees>`, the ticket's steps and expected result `<pasted>`, and where
  its spec lives `<repository and path, or none>`. Without these slots, leave
  out the § Regression test section.

Beyond that worktree, do not change code, tests, branches or commits, and do
not run the e2e suite (it
may buy a real subscription and takes many minutes — read the scenarios instead).
Write exactly one file,
`<absolute path>/docs/qa/<KEY>-tests.md` (in the main checkout, not your
worktree), in `<language — the report language, SKILL.md → Report language: English by default, another language when the requester asked>`, then reply with
its path and the numbers from its header.

## What the file contains, in this order

1. **Header** — commit audited; the test run: passed / failed / skipped; the
   analyzer: issue count (commands: `<app profile → Repo and specs>`); number of cases covered
   / partial / gap. Run the codegen first when generated files are missing —
   without it the numbers are noise, and say so if you had to. Also run the
   feature's own CI gates when it has them (`<app profile → Repo and specs,
   e.g. a copy check>`) and give their results here. For a bug, add the
   regression verdicts from § Regression test: bug cases caught / not.
2. **Coverage map** — one row per AC and per manual case:

   | Case / AC | Layer that covers it | Test (`file:line`, test name) | Verdict |
   |---|---|---|---|
   | P-07 counts line on error | widget | `test/…/library_header_test.dart:88` "hides counts on error" | covered |

   Verdicts: **covered** (a test fails if the behaviour breaks), **partial**
   (a test touches it but would still pass with the behaviour broken — say
   why), **gap** (nothing). Search `test/` for unit and widget tests and
   `<e2e scenarios — app profile → E2E>` for e2e scenarios; a case counts as
   covered by e2e only if a scenario actually asserts it. A scenario that
   exists only on an unmerged branch (`git show <branch>:<file>`) is
   "gap on main — pending on `<branch>`", not covered.
3. **Quality of the tests the change added or edited** — one bullet per
   problem, with `file:line`:
   - asserts existence instead of behaviour (DI registration exists, widget
     found, no exception);
   - asserts an English literal where a key or a structural check would
     survive translation;
   - fixture shape differs from the real payload (field names, types, nulls);
   - cannot fail — mocks return the asserted value, or a negative control
     would still pass;
   - test depends on the machine (directories left by git, local files,
     time zone);
   - swallows an error to stay green — a scenario or test that catches,
     ignores or only logs a specific exception (`takeException`, a
     `FlutterError.onError` override, a try/catch around a step): name the
     error and the step, since it hides an app error every user may hit.
4. **Proposed tests** — one row per gap or partial:

   | Case / AC | Layer | What the test asserts | Where |
   |---|---|---|---|

   Pick the layer by the app's e2e layer rule (`<app profile → E2E>`), or
   without one: business rules → unit, one screen's rendering and state →
   widget, a journey that needs app + backend + real session → e2e. Mark the e2e rows — only those get written in this
   QA cycle.
5. **Existing failures** — any red or skipped test, with its first error line.
6. **Regression test** (bug cycles only) — the tests the fix added or changed
   that drive the condition in the symptom, mapped to the bug's **bug
   cases** — not the manual cases above: each acceptance criterion of its
   spec, a `Regression:` one first, or, with no spec, each condition the
   ticket's steps and expected result name. The spec is
   `specs/frs/<KEY>.md` or, once the fix archived it, `specs/frs/archive/<KEY>.md`,
   at the fix ref — or wherever the brief says it lives (a backend bug's spec
   is in the backend's repository). Prove each test in a worktree
   detached at the fix ref itself (not a later commit): run it — it must pass;
   roll the fix back — for each non-test path in
   `git diff --name-status --no-renames <pre-fix> <fix>` (a move then shows
   as `D` + `A`), `M`, `T` or `D` →
   `git checkout <pre-fix> -- <path>`, `A` → `git rm -q <path>`, codegen again
   if those paths feed it — and run it again: it must fail, the way its bug case
   describes; `git reset --hard HEAD` restores the fix.

   | Bug case | Test (`file:line`, name) | Fix ref | Pre-fix ref (first error line) | Verdict |
   |---|---|---|---|---|

   Verdicts: **catches the bug** (green on the fix, red on the pre-fix code
   the way that bug case describes); **cannot fail** (green on both); **does
   not compile on pre-fix** (name the API that is missing there — the test may
   be fine, but nothing proves it catches the bug). A bug case no test drives
   → a row **missing** for it. Do not write the missing tests yourself — the
   main session does.

Keep each table row to one line. No narrative, no summary of the feature.
