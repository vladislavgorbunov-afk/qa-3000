# Testing the running app on the web

The app-specific half — stand URLs, build commands, accounts, endpoints, cache
TTLs, language rules — is in the profile (`.claude/qa-3000/profile.md`). This file is how
to drive and observe a Flutter web app, whichever one it is.

## Stand

1. **Which build.** A merged change → the deployed stand (profile → Stand):
   check its build number contains the change before you start. A branch, or a
   check that needs the driver → a local build:
   - a worktree at the ref under test, never the teammate's checkout:
     `git worktree add --detach <scratchpad>/wt <ref>`, then the codegen and SDK
     version from profile → Repo and specs;
   - launch in the background, log to a file, with the profile's run command
     (`flutter run … -d web-server --web-port=8787 --web-hostname=127.0.0.1 --target test_driver/app.dart`).
     The `Debug service listening on ws://…/ws` line appears only after a
     browser opens the page.
2. **Accounts** (profile → Accounts) — a user who can reach the feature; for a
   gated feature, one with the entitlement and one without it for the negative
   checks. Read the entitlement from the request the profile names rather than
   trusting a provisioning script's "ok". Credentials go to the chat only —
   never into a report, a ticket or a file in the repo.
3. **Browser** — chrome-devtools `new_page <stand>`, then the view under test
   (below). Close any cookie banner (profile → Stand) before the
   first screenshot — `take_snapshot`, then `click` its close button; it comes
   back in every new profile or isolated context and covers the bottom of every
   shot. A browser restart closes every tab; an isolated context also loses the
   login. Splash forever after that on a local build → restart `flutter run`
   (DWDS wedges when its tab disappears).

## Desktop and mobile view

Every feature is checked in both — never one of them (`SKILL.md` → Phase 2,
Both views). Set the view with one chrome-devtools `emulate` call (each call
replaces the previous emulation, so pass everything at once), then reload the
page with `navigate_page` `type: "reload"`: Flutter reads the platform and the
size at start-up.

| View | `emulate` | The reload |
|---|---|---|
| Desktop | `viewport: "1440x900x1"`, `userAgent: ""` (the browser's own) | no `initScript` |
| Mobile | `viewport: "390x844x3,mobile,touch"`, `userAgent:` an iPhone Safari string (`Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1`) | `initScript: "Object.defineProperty(Navigator.prototype, 'platform', { get: () => 'iPhone' });"` |

- **Width alone is not the mobile view, and neither is the user agent.** An
  app can branch on `defaultTargetPlatform`, which Flutter web takes from
  `navigator.platform` first: on a Mac host that is `MacIntel`, and with at
  most two touch points (emulated touch gives one) Flutter stays on macOS
  whatever the user agent and the width say. The `initScript` makes it
  `iPhone`. It covers one navigation only — pass it again with every reload
  or `navigate_page` in the mobile view. An Android view: `'Linux armv8l'`
  and an Android Chrome user agent. Check the view took, before switching
  semantics on: `evaluate_script`
  `() => [innerWidth, navigator.platform, document.querySelector('flt-semantics-placeholder')?.getBoundingClientRect().width]`
  — Flutter's placeholder spans the whole width when it took a mobile
  platform, and is 1 px wide on desktop.
- Profile → Stand may name the app's own breakpoints or views; then check at
  each of them, still at least one desktop and one mobile.
- The reload drops `scripts/net.js` — install it again after every switch,
  or the second view runs with no network log and no analytics.
- Clear the emulation (`emulate` with no `viewport` and `userAgent: ""`)
  before the next check on the same page.

## Driving

- **Dart MCP present** (`mcp__dart__*`) and a local build: connect it to the
  app's Dart Tooling Daemon and drive with its `flutter_driver` tool (the
  repo's own launch skill, if it has one, says how).
- **Otherwise, local build** `dart run <skill>/scripts/drive.dart <ws-uri> '<json>'`
  (the skill's base directory, see `SKILL.md`) — flutter_driver commands over
  the VM service; `texts` lists every string on screen. Prefer `ByType` with the
  widget class name — `ByText` often matches a title and a button at once.
- **Real browser clicks** (any build): `evaluate_script`
  `() => { const p = document.querySelector('flt-semantics-placeholder'); if (!p) return 'already on'; const r = p.getBoundingClientRect(); p.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: r.left + r.width / 2, clientY: r.top + r.height / 2 })); return true; }`
  switches on Flutter's semantics tree; then `take_snapshot` and `click <uid>`.
  The click must land on the placeholder's centre: on a mobile platform
  Flutter takes only a click within 1 px of it (the way a screen reader taps)
  and switches on ~0.3 s later; a plain `.click()` lands at 0,0 and is
  ignored there. Desktop takes any click on the placeholder.
  These are trusted CDP clicks delivered as `SemanticsAction.tap` — they skip
  hit-testing, so they cannot prove a tap *dead zone* either way.
- **Typing**: `click` the field, then `type_text`. `fill` does not reach
  Flutter's text input. In semantics mode the keyboard can detach a few seconds
  after a send — click another element, then the field again. That "other
  element" must be inert (a heading, the app bar): a click below the field can
  land on a list row and open it. Read the typed value from a screenshot — the
  DOM `input.value` is stale once the field has lost focus.
- **Enter in a Flutter field** (`textInputAction` search / done, no
  `onSubmitted`) drops focus on web, and the next keystrokes go nowhere —
  click the field again before typing more. When the story is about the field
  itself, that is a finding to check, not a harness step to hide.
- **Session after a password change**: setting a test user's password (the
  profile's script) ends its sessions — a saved login state then logs out
  mid-run. Log in again and save the state anew.
- A DWDS timeout on a driver `tap` does not say whether the tap happened —
  screenshot before concluding.
- **No chrome-devtools MCP in the session**: drive the stand with
  `playwright-core` from the scratchpad (`npm i playwright-core@<the version
  whose Chromium is already in ~/Library/Caches/ms-playwright>`), headless,
  500×896. Keep one browser in a small Node process that runs posted snippets,
  so state survives between Bash calls; save the login with `storageState` and
  start every check from a fresh context. Start that process as a tracked
  background task (the Bash tool's background run), not `nohup … &` — that one
  dies with the shell that started it; and check the port first, another
  session's driver may hold it. The same semantics clicks apply:
  click the centre of `flt-semantics-placeholder`, then a real
  `page.mouse.click` at the centre of the labelled node. The mobile view
  takes the same `navigator.platform` override, through `page.addInitScript`.
- **Merged labels**: a parent semantics node carries all its children's text
  (`Topic\nHistory\nChange`, a whole list in one row). Match the exact label
  (`^Change$`), never a substring, or the click lands in the parent's centre —
  on another row.
- The Flutter semantics layer covers iframes: a game's own button inside an
  iframe takes a DOM click from inside the frame (`frame.evaluate(() =>
  el.click())`), not a mouse click.

## Observing

- **Screenshots**: chrome-devtools `take_screenshot` with an absolute
  `filePath: <main checkout>/docs/qa/shots/<KEY>/NN-what-it-shows.jpg` (not the
  worktree — it gets removed), `format: jpeg`,
  `quality: 70`. flutter_driver's `screenshot` crashes on web (`RangeError`).
- **Network**: install `scripts/net.js` once per page load; `window.__qa.log`
  says which hosts and paths the app hit and when. Which of them matter —
  content hosts, version and entitlement endpoints — is in profile → Network
  and analytics. When you keep response bodies, keep content responses whole:
  a catalogue index runs to hundreds of KB, and a body cut at a fixed size no
  longer parses.
- **Analytics**: `window.__qa.amp` holds decoded Amplitude events; another
  vendor → read its requests in `window.__qa.log` and the network panel.
  Check **every** vendor profile → Network and analytics names, not the first
  one that shows the event, and read each vendor's **response**: a request
  that went out but came back 4xx (an unregistered event name, a rejected
  property) is an event the dashboard never gets — a defect even when the
  app looks right. Compare them
  with the app's event classes (profile → Network and analytics) and with the
  same event on the last release tag (`git show <tag>:<file>`): a kept name
  with changed properties breaks dashboards silently.
- **Console**: `list_console_messages` — grep for the error signatures in
  profile → Network and analytics. As a Jira attachment: `new_page about:blank`,
  `evaluate_script` that writes the relevant lines into a `<pre>` (dark
  background, a caption with the ref and the action that triggered them), then
  `take_screenshot` of that page. The same lines also go into Steps as text.
- **Errors on open**: for every screen, sheet and dialog the change adds,
  read the console errors and the error reporter's requests (profile →
  Network and analytics; Sentry: the `…/envelope/` POST — its `level`,
  `exception.values[0].type` and `mechanism.handled`) from the moment it
  opens, before touching anything in it. Something there while the screen
  looks right is still a defect: an unhandled error on every open floods the
  reporter and drags the crash-free rate. Prove it with three runs and two
  controls:
  - open it 3 times from a fresh load, and once the same path without opening
    it — the error must belong to the opening;
  - one opening with Flutter semantics never enabled: no
    `flt-semantics-placeholder` click, a plain `mouse.click` at coordinates
    read from an earlier semantics run. Semantics mode drives text input
    through its own strategy, so an error seen only with semantics on is a
    harness or accessibility-only finding, not one for every user;
  - debug and release builds word it differently — a Flutter assertion in
    debug (an e2e run: "The DOM element of this text editing strategy is not
    currently active") becomes `Null check operator used on a null value` in
    a release build; match them by where and when, not by text.
- **Toasts** vanish in ~3 s; screenshot immediately or watch the semantics live
  region with a `MutationObserver`.
- **Batched analytics**: Amplitude on web sends its batch ~30 s after the
  events. Wait that long before calling an event missing, and confirm with a
  control that other events of the same session did arrive.
- **A PDF the app opens**: fetch its URL with the context's own request API,
  then render page 1 to read it — `sips -s format png file.pdf --out page.png`
  on macOS. Keep the PDF and the image as evidence.
- **Video** — chrome-devtools `screencast_start` (`filePath:
  <scratchpad>/video/<key>-raw.mp4`) before the first step, `screencast_stop`
  after the result. It needs the chrome-devtools MCP started with `--experimentalScreencast
  --experimentalFfmpegPath <path to ffmpeg>` (in the plugin's `plugin.json`
  or your MCP config); a plugin update drops args added there.
  - Frames are captured only on repaint, so put a small HUD on the page: a
    fixed `div` with `pointer-events:none` over an area the defect does not
    need (never the screen title or the control under test), holding the step
    caption, a log of the requests and events that prove the defect, and a
    pulsing dot (a CSS animation). Without the dot the last caption often
    never reaches the file.
  - `click <uid>` draws no cursor: a capture-phase `click` listener can draw a
    ring at the point and log "tap N" in the HUD.
  - The raw file is VP9 / gbrp, which Jira may not play. Re-encode:
    `ffmpeg -i raw.mp4 -vf "scale=720:-2,fps=15" -c:v libx264 -pix_fmt yuv420p -crf 24 -movflags +faststart -an video.mp4`,
    then check three or four frames (`ffmpeg -ss <t> -i video.mp4 -frames:v 1`)
    before attaching.

## Conditions

| Condition | How on web | Notes |
|---|---|---|
| Offline | `window.__qa.block = true` (from `net.js`) | No reload — on web, caches often live in memory and a reload wipes them. Cross the TTLs the profile lists, on both sides |
| Slow endpoint | `window.__qa.delay = {match: '<path part>', ms: 6000}` | Leave-mid-load races: tap Back while it waits, then read the console |
| Forged response | Proxyman map-local, or an XHR / fetch override in the page that answers the matched URL with your status and body | Proxyman-injected 4xx need `Access-Control-Allow-Origin: *`, else the app sees a CORS error |
| A request the app sends at start-up (bootstrap, config, a gating list) | Playwright `context.route` set before `goto` — abort, delay, fulfil with your body, or `continue({url})` to rewrite it | `net.js` arrives after the app has loaded, too late for these. Clear only the feature's own `localStorage` keys (`flutter.<key>`) in an init script — clearing all of it logs the user out |
| A defect that blocks the rest of the flow | Rewrite or forge the one failing request (`continue({url})`, `fulfill`) and go on | Name the forced condition in every result and step it produced; the defect itself is reproduced first without it |
| Pop-up blocked | Init script `window.open = () => null` | A real `window.open` gives the context a new page — wait for its first request to read the URL |
| 404 / broken content | Open an id that does not exist | |
| Large text | `document.documentElement.style.fontSize = '32px'` (×2), `'48px'` (×3); `''` resets | Flutter web derives the text scale from the root font size |
| Start a session in a language | profile → Language | Clearing `localStorage` is usually part of it |
| Test the language switch itself | The in-app language picker; clear nothing | Clearing `localStorage` wipes the stored choice the switch is supposed to keep |
| Browser locale (formats, Accept-Language) | a separate browser pinned to that locale (a `locale-browser`-style skill, or Chrome started with `--lang` plus, on macOS, `-AppleLanguages`) | chrome-devtools cannot drive that browser; none at hand → Needs a human |
| Narrow screen | the mobile view's `emulate` with `viewport: "320x640x2,mobile,touch"` | Not the same as a 320 dp phone with a large system font |

## Web cannot tell you

Safe area and notches, the system back button and swipe-back, the native
clipboard and share sheet, in-app purchases, push and deep links from outside
the app, the disk cache across a relaunch. These go to the **Needs a human**
table with the device, the setting and three steps.
