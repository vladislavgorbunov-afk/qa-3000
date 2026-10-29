# Charters — exploration beside the checklist

The checklist tests what you thought of. A charter hunts for what you did
not: one area, one posture, one sentence, explored by its own subagent in
its own browser and account for a fixed time. Charters run in parallel with
your live run (phase 3b), and what they report are leads for 3c — never
results, never Jira, until you reproduce them.

## Write them (phase 2, after the checklist)

Three to five charters, at most five. Pick each one from where the change
is and where the checklist is thin: the screens the diff touches, its
neighbours, the states the checklist only names once. A posture the change
has no surface for is skipped — no input field, no fuzzer.

| Posture | The posture's instruction (goes into the brief verbatim) | Charter shape |
|---|---|---|
| first-time user | Use the area as someone who has never seen the app: read every label, follow the obvious path, then the less obvious one. Report anything confusing, inconsistent, or that leaves you without a way forward. | `Starting at <screen>, use <feature> like a first-time user; report anything confusing, broken or inconsistent` |
| numbers and copy (skeptic) | Distrust every number, date, count, status and claim on screen. Cross-check each against every other place it appears and against what you just did; read every string for truncation, placeholders, wrong language and wrong plural. | `Starting at <screen>, <do the thing that changes counts>; check every count, status and label against the rest of the app` |
| edge input (fuzzer) | At every input, run this matrix before anything else, judging each entry before the next: empty, one space, leading and trailing spaces, 300 characters, emoji and right-to-left text, `<b>x</b>` and `'; --`, a pasted line break. Never take the happy path first. | name the exact inputs: `Starting at <screen>, submit <field> with each entry of the matrix; report validation that is missing, wrong or crashes` |
| state | After every change: reload, Back, reach the same screen from another entry point, log out and in again. Report state that is lost, stale, duplicated, or shows up for another user. | `Starting at <screen>, <change something>, then reload, go back and come again from <other entry>; report state that is lost or stale` |
| error paths | Cut the network, slow one endpoint, open an id that does not exist, double-tap every action, leave mid-load. Report errors that are missing, misleading, leak detail, or leave no way out. | `Starting at <screen>, with the network cut / <endpoint> slowed, <do the thing>; report what the user is left with` |

Each charter is one line in `<KEY>.md` § Charters:
`slug · posture · start screen (NAV id) · account · charter sentence`, and
after the run its result: ended, findings, not reached. A charter that spans
the whole app ends at its budget having skimmed everything — one area each.
Check its path in the navigation map first: a charter whose screen sits
behind long content — a lesson that is a game, a whole onboarding — spends
its budget getting there (the first pilot did: 48 actions inside a game, the
completion screen it was sent to check never reached). Start it on the
screen it is about, or make the long content itself the area.

## Accounts

One account per charter, every charter: explorers sharing an account report
each other's edits as bugs, and a "read-only" explorer still logs out, reloads
and changes settings. So the cycle costs up to five more test users — say so
at Stop 1. Create them in parallel before the dispatch (profile → Accounts),
with the entitlement each posture needs (a gated feature's error-path charter
may need the account without it). List every one at cleanup.

## Browsers

Every charter works in the session's own chrome-devtools browser — a
chrome-devtools MCP whose tools take a `pageId` (1.9 or newer: check that
`take_snapshot` has the parameter; without it the explorers drive each
other's pages, so no charters) — in an isolated context of its own: `new_page` with `isolatedContext: "<slug>"`
opens a separate window with its own cookies and storage, so explorers on
different accounts never see each other's session. Every chrome-devtools
tool takes a `pageId`, so each explorer drives only the page it opened —
the brief forbids `select_page` and any other page. Measured on 20.10.2026:
two charters and the main session's own page at once, each window rendering
at 60 fps whether in front or not, no explorer touched another's page, and
Chrome stayed under 10 % CPU.

That browser's profile is one per machine: a second session that holds it
(`The browser is already running for …/chrome-profile`) blocks your live
run and every explorer alike. Phase 0's baseline (step 3) shows it; name it
at Stop 1 — the user frees it, or the cycle runs without a browser.
Charters need a deployed stand: on a local `flutter run` debug build their
tabs coming and going wedge DWDS under your own run.

## Dispatch

All charters in one message, each an Agent call (the default
general-purpose subagent) with `run_in_background: true` and
`prompts/charter.md` filled in. Fill the posture's instruction from
the table above verbatim, the "Not bugs here" slot from profile → Known — do
not file and the prior report, the start screen from the navigation map, and
the view: alternate desktop and mobile across the charters so each view gets
at least one.
They run while you walk the checklist; you do not wait for them. Keep your
own work on your own page's `pageId` too.

Budget: 15 minutes and at most 60 browser actions each. What that costs,
measured on 20.10.2026 against five earlier cycles of this skill:

| | One charter | Four charters | A cycle without them |
|---|---|---|---|
| Wall clock | 2–11 min (35–48 browser actions) | ~0 added: they run beside the live run | live run 45–150 min |
| Tokens, raw | 4–9 M (context 60 k → 140 k) | ~20–36 M, +6–19 % | 190–355 M |
| Tokens, input-equivalent (cache reads at a tenth) | 0.5–1.2 M | ~2–5 M, +5–20 % | 24–43 M |

The real time they add is in 3c: every candidate they bring is a replay of
5–15 minutes. A charter that brings only
rejected leads costs its tokens and nothing else.

## Merge and sort (the start of 3c)

Merge findings that describe one defect — same screen, same broken
behaviour — keeping the clearest steps and every charter that hit it. Then
sort **every** lead — the charters', the diff review's, the audit's, your
own from the live run — before you write a single step:

| Bucket | The sign | What happens |
|---|---|---|
| Tool artifact | A synthetic event that never reached Flutter, a reload that wiped an in-memory cache, a toast gone before the screenshot, a driver or DWDS timeout, semantics not switched on | Rejected, naming the control that settled it (the control click, the run without the reload) |
| Environment | A stage-only limit or a missing key or service (profile → Known — do not file names the stand's) | The cause is rejected, naming the limit. How the app **handles** it is not: a raw error or a dead end on screen is a candidate — force the same failure on web in 3c (`net.js`, a forged response) and reproduce it there. Only when web cannot produce that failure at all does it become a line under **Production risks (not checked)** |
| Design | The spec, an acceptance criterion, a code comment or a ticket says it is intended; profile → Known — do not file | Rejected, citing where |
| Data | The stage data lacks what real data has: a one-course catalogue, a missing locale's content | Rejected, naming the data |
| Candidate | None of the above | Reproduce it (3c) |

The rejected leads go to the report's § Rejected, with the reason, grouped by
these four buckets. A candidate that 3c then cannot reproduce goes where 3c
sends it — open questions for the developer, with what was tried — and
nowhere else. A charter's finding never skips this table because a model
was confident.
