# Jira through dev-process-toolkit (optional module)

For teams that run [dev-process-toolkit](https://github.com/nesquikm/dev-process-toolkit)
and share one Jira project between several repositories. Off unless profile →
Jira turns it on with an **Overrides:** line; `jira.md` still gives the shape
of a bug, its priority and the attachments.

## Why the writes go through the toolkit

When the app's CLAUDE.md declares its Jira project a shared tracker container,
the dev-process-toolkit hook `pre-tracker-write-gate` refuses an MCP write to
that project unless the toolkit's own commands decided it first. The profile
says so in an **Overrides:** line under Jira. Jira then gets the bug and
nothing else — no milestone or Epic; a bug's spec, when the profile asks for
one, lives in the app's repository (below). The agent writes
to that project through the MCP only; REST stays for uploading attachments to
a ticket this checkout owns. Never a create, edit or link around the toolkit,
REST included: the hook does not see REST, the rule still holds.

**One checkout, one toolkit copy.** Receipts count only in the checkout that
announced them, and the hook reads that checkout's working-tree CLAUDE.md
(the branch it is on, not `main`). Run every check, deciding command and Jira
write of phase 5 from the app's main checkout, set as the shell's working
directory in a Bash call of its own. `<toolkit>` is the plugin root the hooks
run from, written as an absolute path: the cache copy
`<home>/.claude/plugins/cache/dev-process-toolkit/dev-process-toolkit/<version>`
for a marketplace install, `<checkout>/plugins/dev-process-toolkit` for a
directory one. A hook refusal prints that root in its first line; when a
receipt is ignored although the command was plain, the copy differs — rerun
from the root the refusal names. The hook counts only a plain invocation: no
`cd … &&`, pipe, redirect, `~` or `$` in the command.

**Before Stop 1**, two checks; either failing, or the user turning the
Override down at Stop 1, means the agent writes nothing to that project and
every Stop 2 draft goes to the user to file or post by hand:

- `bun` sits where Claude Code's own environment finds it (a Homebrew install
  in `/opt/homebrew/bin` or `/usr/local/bin`), not only on a shell-profile
  path such as `~/.bun/bin`: the hooks `exec bun` with that environment and,
  without it, pass everything silently.
- `bun run <toolkit>/adapters/_shared/src/workspace_binding.ts <checkout>`
  prints the binding as one JSON line, then `running=<version> floor=ok`.
  `floor=refused` → too old. The JSON also decides who creates bugs: the
  agent, when its `milestoneExemptIssueTypes` lists the profile's bug type
  (a toolkit with nesquikm/dev-process-toolkit#114 and the key in that
  checkout's CLAUDE.md); otherwise the user. Name the answer in the Stop 1
  round.

The Atlassian MCP is needed as well; without it the drafts go to the user.

## Filing a bug

- **The agent creates it** (the bug type is in `milestoneExemptIssueTypes`):
  1. The Summary goes into `<scratchpad>/title-<n>.txt` (no trailing newline)
     and every command below takes `--title-file` with it — quotes and
     apostrophes in a summary break a plain invocation otherwise.
  2. `bun run <toolkit>/adapters/_shared/src/create_idempotency_probe.ts query <checkout> --title-file <file>`
     prints one JSON line with `jql` and `fields`.
  3. `searchJiraIssuesUsingJql` with exactly that `jql` and those `fields`.
     Each page verbatim into `<scratchpad>/dup-<n>-<page>.json`; a page after
     the first gets one added top-level key, `requestCursor`, holding the
     `nextPageToken` that page was requested with.
  4. `… create_idempotency_probe.ts decide <checkout> <pages> --title-file <file> --attempt fast`:
     `reused` → the bug already exists under that key, no create; `refused`
     → stop and ask; `create` → step 5.
  5. `createJiraIssue`: the profile's bug type, the Summary byte for byte,
     the labels of the printed `createPayload` (the repo tag is among them),
     priority, components, no parent. Then
     `editJiraIssue` with one ADF doc per role field, the `Relates` link and
     the attachments, as `jira.md` says: the ticket was created in this session, so
     they need no ownership step.
- **The user creates it** (anything else): the Stop 2 draft carries every
  field the Jira form asks for — type, Summary, the repo tag as a label (a
  ticket without it cannot take the agent's follow-up writes), priority,
  components, the role-field texts. The user answers with the key; the agent
  runs the ownership step below and adds what is left: attachments, the link,
  a missing field.

**A bug that belongs to another repository** sharing the project — the
profile names its label — is never created by the agent: the toolkit puts
this repository's tag on every create the agent makes. The user files it by
hand with the other repository's label, and since it is then that
repository's ticket, its attachments and any edit go to the user too, with
the draft. A plain `Relates` link from a story this checkout owns still goes
through. Its spec still goes to its own repository when the profile lists it
(below).

**A refusal is not a to-do list.** The hook's remedies point at milestone
decisions, attach targets and `decide --attempt retry-<N>`. Follow none of
them. The one retry is running `decide` again, and only while no create for
this bug has been sent. Anything else, or a create that timed out, stops the
filing — the draft goes to the user, who checks Jira for the ticket first.

## The bug's spec in the repository

Every bug whose repository the profile lists under its spec repositories
gets its spec in that repository — the app's own for its bugs, a sibling's
(the backend, say) for the sibling's bugs, by the same steps:
`specs/frs/<KEY>.md`, plus a milestone plan `specs/plan/M<N>.md` (`N` = the
key's number) when the profile names a plan for that repository. The spec is
the toolkit's bug FR (`kind: bug`): the toolkit then holds the developer who
takes the bug to the test its `Regression:` criterion names, so the cycle
writes no test for it. Where it goes follows the profile's "Spec PRs merge
themselves" for that repository:

- **Yes** — on a spec branch of its own, whose PR lands on the trunk as soon
  as it is opened: the repository's workflow marks it ready and merges it.
  Never mark it ready or merge it yourself — the workflow does, and an
  agent's merge is refused anyway. The developer cuts the fix branch from the
  trunk, the spec already there. A spec on the trunk turns the toolkit's
  active-ticket probe (#14) red there for everyone but the bug's developer
  until its ticket is Done: Backlog fails it, and so does In Progress for
  anyone but the assignee. That is accepted.
- **No** — on the fix branch, with a draft PR that the developer who takes
  the bug continues, so the spec lands with its fix. A spec PR of its own
  would wait there as a draft nobody reviews, and the fix branch would start
  without the spec. This PR is never merged as a spec PR: it is the bug's
  PR, the developer pushes the fix to it, and it merges once, with the fix,
  after review. Its body says so right under the ticket link, and it is
  assigned to the profile's spec PR assignee for that repository, when it
  names one.

A repository the profile does not list, or one the user cannot push to yet,
gets no spec — name the bug in the report instead. This step writes nothing
to Jira.

The agent writes the spec files itself, not with
`/dev-process-toolkit:spec-write`: in a tracker mode spec-write mints a
milestone only as an Epic and refuses a typed `M<N>`, and its import builds
the spec from the system Description, which a bug leaves empty.

**Never leave the shell inside a worktree.** The Jira writes run from the
main checkout (above); a `cd` into a worktree that outlives its command
makes the next Jira write come from another checkout, which the hook refuses.
Address a worktree with `git -C <wt>`, a path argument, or a
`( cd <wt> && … )` subshell — with the path written out, never in a shell
variable: the commit hook places a commit by reading the command, and a
`$VAR` hides the target, so the commit is graded against the main checkout
and refused.

**Before Stop 1**, per listed repository: its clone exists where the profile
says (`git clone` it there once if not) and
`gh api repos/<owner>/<repo> --jq .permissions.push` answers `true`. Name the
repositories that fail in the Stop 1 round: their bugs get no spec. Where
the profile names a spec PR assignee, `gh api repos/<owner>/<repo>/assignees/<login>`
answers 204; otherwise `gh pr create --assignee` fails and opens no PR — name
it in the same round, and open that repository's PRs without an assignee.

1. **A worktree from the repository's trunk**, never the user's checkout:
   `git -C <clone> fetch origin`, then
   `git -C <clone> worktree add --detach <scratchpad>/wt-spec-<repo> origin/<trunk>`
   once per session. The bugs' branches come in step 6, after the "yes",
   when every key is known.
2. **The FR**, keys, heading form and section order of that repository's
   example spec in the profile, its prose not copied (the example may break
   the caps below), in the toolkit's bug FR shape:
   - frontmatter, in this order: `title: "<Summary>"` (double-quoted, inner
     `"` escaped as `\"`), `milestone: M<N>` (or `null` where the profile
     names no plan), `status: active`,
     `archived_at: null`, `tracker:` with `jira: <KEY>` on the next line
     indented two spaces, `created_at:` (now, ISO 8601), `kind: bug`,
     `changelog_category: Fixed`, `needs_technical_review: true`;
   - the example's title heading with this key and Summary, e.g.
     `# <KEY>: <Summary> {#<KEY>}`;
   - `## Summary`: 3–6 lines of plain prose about what the user sees — at
     most 80 words, no sentence over 20 words, no backticks, no file paths,
     no AC ids;
   - `## Requirement` with three subsections, as in the role fields:
     `### Steps to reproduce` (numbered, from a clean state), `### Expected`,
     `### Actual`;
   - `## Acceptance Criteria`: first
     `- AC-<KEY>.1: Regression: a test that <drives the condition in the steps> and asserts <the expected result> fails before the fix and passes after it.`,
     then one `- AC-<KEY>.<n>: …` line per expected behaviour from *how it
     should be*;
   - `## Technical Design` and `## Testing`: each the line
     `[needs technical review — run /spec-write <KEY> to complete]`, exactly —
     the toolkit's `needs_technical_review` probe wants it in both while the
     flag is `true`, and its bug-shape probe accepts it for the root cause.
     When the cycle found the cause (the file and the faulty assumption), add
     `### Root cause` with it under `## Technical Design`, beside the line;
   - `## Notes`, at most 60 words: the ticket, where and on which build it was
     reproduced, and `milestone_attach_skipped_adapter_limit` — the milestone
     is local only, by design.
3. **The plan**, only where the profile names one, in the example plan's
   shape: frontmatter `milestone: M<N>`,
   `status: active`, `archived_at: null`, `kickoff_branch: <fix branch>` —
   named by the repository's CLAUDE.md branch template with type `fix`; the
   developer cuts it where spec PRs merge themselves, and it is the spec's own
   branch elsewhere — `frozen_at: null`, `migration: none` and the `kind` the
   profile names; then `# Implementation Plan — M<N>`,
   `## M<N> — <Summary> {#M<N>}`, a one-sentence **Goal**, the **FR list**
   table with its one row, **Tasks** with a single
   `- [ ] Fix <KEY> (AC-<KEY>.1 – .<n>) — <KEY>`, the **Gate** line from that
   repository's CLAUDE.md and **Dependency graph**: standalone.
4. **Check the drafts.** Copy them into the worktree, then
   `bun run <skill>/scripts/spec_probes.ts <toolkit> <wt> '<keys regex>'`
   (e.g. `'APP-48[2-6]|M48[2-6]'`): the toolkit's spec probes, the bug-shape
   one included, rows for these keys only. Every one clean before the Stop 2
   draft; a row is fixed in the draft, never argued.
5. **The commit gate's receipt.** Invoke `/dev-process-toolkit:gate-check <wt>`
   and run its first command, the receipt
   (`bun run <toolkit>/adapters/_shared/src/gate_receipt.ts gate-check <wt>`),
   before anything else; at its ticket-binding question answer No — the gate
   then ends without reading or writing Jira, and the receipt the commit hook
   wants stays. Once per worktree.
6. **Branch, commit and push**, one bug at a time, each on a fresh branch
   from the trunk: `git -C <wt> switch -c <branch> origin/<trunk>`, named by
   that repository's CLAUDE.md branch template — type `docs` where spec PRs
   merge themselves, `fix` elsewhere. The drafts copied in at step 4 carry
   over as untracked files; one drafted before its key existed gets the real
   key now, and the spec probes run once more. Never rename a branch once its
   PR is open: GitHub closes a pull request whose head branch is renamed.
   `git -C <wt> add` the bug's spec files, then `git -C <wt> commit` with the
   subject the profile names for that repository — a `docs` type, never
   spec-write's `chore(specs): write FR <KEY>`, which gate-check reads as a
   spec-write commit made without its gates. Where spec PRs merge themselves,
   that subject is also how the repository's workflow tells a bug's spec from
   a developer's: keep it exactly, and put nothing else on the branch, or the
   PR waits for a review. Then `git -C <wt> push -u origin <branch>`.
7. **The PR.** `/dev-process-toolkit:spec-review <wt>/specs/frs/<KEY>.md` once
   per worktree: the PR hook wants the skill run and its receipt in the
   repository the PR is for. In Jira mode it reads the ticket's ACs
   from the empty Description and stops — the bug's ACs live in the spec — so
   record its receipt with the command the skill itself runs,
   `bun run <toolkit>/adapters/_shared/src/gate_receipt.ts spec-review <wt>`,
   and go on. Then
   `( cd <wt> && gh pr create --draft --base <trunk> --head <branch> … )`:
   title the commit subject; body what the spec records, the bug key and that
   it was written from the reproduced bug — on a fix branch, also that the
   developer continues the fix on it, with
   `**Do not merge on its own** — the <KEY> fix lands on this branch.` as the
   line under the ticket link, and `--assignee <login>` from the profile's
   spec PR assignee; no future-work block, no reviewer
   unless the user names one. Where spec PRs merge themselves, wait for its
   `merge` check to finish, `gh pr checks <n> --watch` (right after the PR
   opens it may say there are no checks yet — run it again), then read
   `gh pr view <n> --json state,autoMergeRequest`. `MERGED` is done. Open
   with auto-merge on means the trunk's rules still want something (an open
   review thread, say), and it lands once they are met. Open without it goes
   into the report with the reason the check's log gives
   (`gh run view <run id> --log`; the run id is in the `merge` check's link,
   `gh pr checks <n> --json name,link`), a conflict with the trunk, say.
   Never merge it yourself.
8. **The ticket link.** The key in the branch, the commit subject and the PR
   title lets the Jira GitHub integration list the PR in the ticket's
   Development field (profile → Jira names it); the PR body opens with the
   ticket's link for the other direction. After the PRs are open, read that
   field for each ticket: a `pullrequest` entry means linked. Its summary is
   cached (`isStale`) and lags by minutes — read again later; still absent
   after that → draft a comment on the ticket with the PR's link, which goes
   through the ownership step and the user's "yes".

Steps 1–4 run before the Stop 2 draft, which shows the files of each spec
(with `<KEY>` where the key is not known yet) and their probe result, and,
where spec PRs merge themselves, says the spec lands on the trunk at once;
elsewhere it names the PR's assignee, since GitHub notifies that person.
The "yes" covers writing them with the real key filled in, the branch, the
commit, the push, the PR with its assignee, the spec landing on the trunk
where it merges itself, and the link check. Phase 6 removes every `wt-spec-<repo>` after the
last PR is open.

## Writing to an existing ticket

The hook lets a write through only on a ticket this checkout owns: created in
this session, bound by an FR file on the checkout's current branch, or
confirmed by the ownership command. Before a comment, an edit, a link or an
attachment on any other ticket:

1. `getJiraIssue` with `fields: [summary, issuetype, labels, description, creator, project, status]`
   — `decide` refuses a ticket without `creator` or `labels` — and the
   result verbatim into `<scratchpad>/<KEY>.json`.
2. `bun run <toolkit>/adapters/_shared/src/ticket_ownership.ts decide <checkout> <scratchpad>/<KEY>.json`
   prints the verdict:
   - `owned` → `… ticket_ownership.ts confirm <checkout> <KEY> <scratchpad>/<KEY>.json`;
   - `unowned` → AskUserQuestion whose question names the key, with the option
     `Adopt <KEY>`; on exactly that answer, `confirm … --adopt`;
   - `foreign-repo`, `foreign-project`, `container` → no write from here, an
     attachment included: the draft and the files go to the user. Any label
     other than the repo tag, a `milestone-` one or `needs-technical-review`
     makes a ticket another repo's.
3. Then the write.

A link needs one owned side only, as long as it carries no `comment`: a
plain `Relates` link from a bug created in this session goes through
whatever the story's labels; a comment on a link needs every side owned.

