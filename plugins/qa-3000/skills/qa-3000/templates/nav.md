# <App> — navigation map

<!-- The app's navigation map for the qa-3000 skill: .claude/qa-3000/nav.md in
the app's repo, committed. Local additions between PRs go to
docs/qa/nav/pending.md; the plugin's hook shows both before the first
navigation action of a session. Rules: <skill>/reference/navigation.md. -->

How to reach a screen without searching. **Read this before navigating** (web,
Android, iOS); after the cycle, add what you learned (a new route, a new dead
end, a route that broke).

Steps are **visible labels** (Flutter semantics), so one route works on every
platform:
- web — enable semantics first (trusted click on `flt-semantics-placeholder`),
  then `take_snapshot` → `click <uid>`; sheets and dialogs may be missing from
  the plain snapshot — take a `verbose` one;
- Android — `<skill>/scripts/tap_text_android.sh "<label>" [serial]`
  (uiautomator; `--list` prints labels and their centres);
- iOS simulator — `<skill>/scripts/tap_text_ios.sh "<label>" [udid]` (AXe).

Labels follow the app language. Statuses: `ok` (worked on the build in
*verified*) · `stale` (not verified for 3 releases — re-check on the way) ·
`broken` (failed; replacement noted).

## Routes

### NAV-<kebab-name>
- goal: the screen or state reached
- entry: where it starts · tier · platforms
- steps: label → label → label
- alt: another way, if one is known
- done-when: what proves arrival
- gotchas: overlays, timing, platform differences
- verified: <stand/build> · <date> · ok|stale|broken · cost <N> actions

## Dead ends

| What | Where | Use instead |
|---|---|---|
