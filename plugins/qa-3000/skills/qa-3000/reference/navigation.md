# Navigation — map, tap by text, metrics

An app's navigation map is `.claude/qa-3000/nav.md` in the app's repo (start one from
`<skill>/templates/nav.md`). The plugin's hook (`hooks/hooks.json` → `scripts/nav_map_hook.sh` →
`scripts/navlog.py`) puts the map — and the app repo's local `docs/qa/nav/pending.md` — into an
agent's context before its first navigation action: the main session and each subagent (a charter)
get it once, and again after a compaction. It logs every navigation action — chrome-devtools and
Playwright clicks, navigation and typing, iOS simulator control, `adb input` — to
`docs/qa/nav/nav-log.jsonl` in the app repo's main checkout, where the helpers below log too, also
from a worktree. A repo with no map: the hook does nothing.

## Before you navigate

1. Look the screen up in the map. A route fits → `scripts/nav_mark.sh start <target> <NAV-id>`;
   none → `scripts/nav_mark.sh start <target> search`.
2. Walk the steps by **visible label**, not by screenshot coordinates:
   - **Android** — `scripts/tap_text_android.sh "<label>" [serial]` (uiautomator; `--list` prints
     the labels with their centres; exit 2 = not found or not tapped, it prints why and what is
     visible; 4 = the UI dump or the tap failed). On a physical device only when the user said
     you may drive it; otherwise give them the same steps.
   - **iOS simulator** — `scripts/tap_text_ios.sh "<label>" [udid]` (needs AXe:
     `brew install cameroncooke/axe/axe`). It scans the screen with `axe describe-ui --point`
     because the full `describe-ui` fails on Xcode 27 / DeviceHub, so a tap takes ~10 s — and
     several times that when the 60 pt pass does not settle the label and a 30 pt pass runs.
   - **Web (Flutter canvas)** — switch semantics on with the click at the centre of
     `flt-semantics-placeholder` (`reference/live-web.md` → Driving), then `take_snapshot` →
     `click <uid>` of the label; a sheet or a dialog missing from the snapshot shows in a `verbose`
     one.
   The two native helpers tap the whole label first, else the one single-line label that contains
   the query (`scripts/tap_match.py`). A query found only inside a merged label
   (`Topic | Finance | Change`) is not tapped — that node's centre is another element; pass the
   whole label to tap the card itself.
   Screenshots are evidence and the fallback for screens without labels (a game WebView), not the
   way to find a button.
3. Mark the way: `nav_mark.sh deadend "<what>"` for every wrong turn or locked screen,
   `nav_mark.sh human "<what>"` when you had to ask a person, `nav_mark.sh done <target> ok|fail` on
   arrival. `scripts/nav_report.py` prints per target: actions, seconds, dead ends, human asks, and
   the map hit rate — for this session's main agent (`--all` for every session; subagents'
   actions never count).

## After the cycle (phase 6)

Write to the app repo's `docs/qa/nav/pending.md`, in the map's own format:
- every `search` that reached its screen → a new route (steps by label, tier, platform, verified
  build and date, cost);
- every dead end or tier limit → a row of the dead-ends table;
- a route that failed → `broken` with the date, the build and the replacement;
- a route you walked → its *verified* line updated; one not verified for 3 releases → `stale`.

Put the `nav_report.py` table into § Verification. At Stop 2 offer `pending.md` merged into
`.claude/qa-3000/nav.md` as a draft PR to the app's repo, then empty `pending.md` once it is merged.

## Map entry format

```markdown
### NAV-<kebab-name>
- goal: the screen or state reached
- entry: where it starts · tier · platforms
- steps: label → label → label
- alt: another way, if one is known
- done-when: what proves arrival
- gotchas: overlays, timing, platform differences
- verified: <stand/build> · <date> · ok|stale|broken · cost <N> actions
```
