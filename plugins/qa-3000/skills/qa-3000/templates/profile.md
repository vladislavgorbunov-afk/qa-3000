# <App> — QA profile

<!-- The app's profile for the qa-3000 skill. It lives in the app's repo as
.claude/qa-3000/profile.md, committed, so everyone who runs the skill shares
it; a first draft goes to docs/qa/profile.md and becomes a PR at Stop 2. Fill
what the repo and the APIs show (CLAUDE.md, pubspec, e2e scripts, CI, Jira
field metadata, TestRail projects), ask the rest at Stop 1. Keep the headings:
SKILL.md and the references point at them as "profile → <heading>". A section
that does not apply says "none" and why — that turns its step off. To change a
SKILL.md default (where the live run happens, when the e2e regression runs,
how Jira is written), write a line starting with **Overrides:** and give the
reason; anything else follows SKILL.md. Never put passwords or tokens here:
name the file or the secret store they come from. -->

Repo `<owner>/<repo>` · <stack> · Jira `<PROJECT>`.

## Repo and specs

- SDK and version (where it is pinned), the version wrapper (`fvm`?).
- Codegen or other steps before the code compiles.
- Test, analyze and CI-gate commands (e.g. a copy check), as CI runs them.
- Shared packages pinned by version, and where to read their source at that pin.
- Where specs and acceptance criteria live. Key format for two stories.
- PR edits: `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -F body=@<file>`.

## Jira

- Host · cloud id · project · issue type for bugs.
- Bug fields, by role:

  | Role | Field |
  |---|---|
  | what's wrong | `<field id>` or "Description section" |
  | how it should be | |
  | steps | |
  | additional details | optional: a field for the cause, logs and related tickets |

- Components and when to use each.
- Priority paths for `reference/jira.md` → Priority: the money paths
  (paywall, purchase, restore, sign-up, sign-in, anything bought) and the
  core flow, by screen.
- Prior bugs on an area: the JQL.
- The Development field id (PRs, branches and commits the Jira GitHub
  integration links by key), when the project has the integration.
- Optional — the dev-process-toolkit module. The app's CLAUDE.md declares the
  project a shared tracker container (dev-process-toolkit)? → an
  **Overrides:** line: Jira writes go through the toolkit
  (`reference/jira-dev-process-toolkit.md`), with the repo tag, the costs,
  how bugs from other teams are labelled, and a spec-repositories table — per
  label: repository, trunk, clone path, example bug spec, plan (`M<N>` with
  its `kind`, or none), commit subject, and whether spec PRs merge themselves
  (yes only when the trunk's rules need no approval for the spec paths and a
  workflow merges such a PR — name both), and the spec PR assignee where they
  do not (the GitHub login of the developer who takes that repository's bugs,
  or none); who creates a bug is decided at run time by that module's binding
  check, not in the profile. No toolkit → leave this item out.

## TestRail

- Project id and name, suite id and name — or "none".
- Where a feature's subsection goes; default `priority_id`; template or type
  ids that differ from TestRail's defaults; custom fields that are not
  enabled; whether cases carry the story key in `refs` (default: no).
- Where the credentials for `scripts/testrail.py` come from (env vars or a
  config file outside the repo).

## Stand

- Deployed stands (URL, which backend, how fresh) and where each shows its
  build number; how to find the first build with a commit.
- Local build: the run command, how it selects the environment.
- The app's own breakpoints or views, if it has more than desktop and mobile.
- Banners or overlays to close before screenshots.

## Accounts

- How to get a test user (script, flags, cost), with and without an
  entitlement; extra setup a fresh user needs to reach the app.
- Where the entitlement is visible (request → field).
- Secrets the scripts read and where they live.

## Network and analytics

- Hosts and endpoints worth watching, cache TTLs worth crossing.
- Analytics vendors and where the event classes live.
- Error signatures worth grepping in the console (crash reporter lines, router errors).

## Language

- How the app picks its language; how to start a session in another one.
- The team's report language, if not English.

## E2E

- Framework, the skill that has its rules and failure triage, where scenarios
  live — or "none".
- The layer rule: what belongs in e2e and what in unit / widget tests.
- How to run the whole suite (command, worktree prep, duration, cost).

## Extra checks

Checks this app adds to phase 2 for certain kinds of change, with their
procedure. "none" when there are none.

## Known — do not file

Findings the team ruled "by design" or already tracks. One line each, with who
decided and when.
