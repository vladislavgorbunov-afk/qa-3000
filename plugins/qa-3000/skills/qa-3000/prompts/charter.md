# Brief for a charter subagent

One background subagent per charter (`reference/charters.md`), all
dispatched in one message with the Agent tool, `run_in_background: true`, at
the start of phase 3b. Fill the `<…>` slots; send everything below the line
as the prompt.

---

You explore one area of `<app>` for `<budget: 15>` minutes, like a tester
with a charter, not a script. Your findings are leads that the main session
reproduces before anything is filed, so report what you saw, with evidence,
and do not argue severity.

**Charter** `<slug>` — posture **`<posture>`**: `<the charter sentence>`

How you work, from the posture: `<the posture's instruction from
reference/charters.md, verbatim>`

- Stand: `<URL>`, build `<build number>` (the change under test is in it).
- Account: `<email>`, signed in by opening `<one-time login link>` — the link
  works once; if you lose the session, log in with the password `<password>`
  (`<where the password login is>`). This account is yours alone.
- View: `<desktop | mobile>` — set it right after `new_page` with one
  `emulate` call and a reload, exactly as `reference/live-web.md` → Desktop
  and mobile view gives it: `<the emulate arguments>`, then `navigate_page`
  `type: "reload"` with `<the reload's initScript, or none for desktop>`.
  Stay in it: in the mobile view pass that `initScript` with every reload or
  navigation, or the app falls back to its desktop platform.
- Start screen: `<screen>`, reached by `<route from the navigation map, by
  visible label>`.
- Stay inside: `<the area's boundary — the screens this charter covers>`.
- Never touch: `<destructive or paid controls: cancel subscription, delete
  account, a purchase, sending real email>`.
- Not bugs here: `<profile → Known — do not file, plus the prior report's
  not-filed block>`.

## Your browser

For the browser use only the chrome-devtools tools: load their schemas
first, all at once, with ToolSearch `select:` naming new_page,
navigate_page, take_snapshot, click, type_text, press_key, take_screenshot,
evaluate_script, emulate, list_console_messages, list_network_requests,
get_network_request and close_page (`max_results: 13`). The browser is
shared — other explorers and the main session work in it at the same time —
so:

- open your own page: `new_page` with `isolatedContext: "<slug>"`,
  `background: true` (a window in front would take the keyboard from the
  main session) and the login link; note its `pageId`. The isolated context
  is your own cookie jar and window;
- pass that `pageId` on every call; never call `select_page`; never touch,
  navigate or close any other page;
- when you are done, `close_page` your own page and nothing else.

First close the cookie banner, `<the banner — profile → Stand>`: it comes
back in every new isolated context and covers the bottom of the screen.

Flutter web draws on a canvas. Before the first snapshot, switch its
semantics tree on: `evaluate_script` with
`() => { const p = document.querySelector('flt-semantics-placeholder'); if (!p) return 'already on'; const r = p.getBoundingClientRect(); p.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: r.left + r.width / 2, clientY: r.top + r.height / 2 })); return true; }`
(the click must land on the placeholder's centre — the mobile view ignores
any other), then `take_snapshot`. Only if the snapshot still shows nothing but an
`Enable accessibility` button, `click` that button's uid. From then on,
`take_snapshot` → `click <uid>`. **After every reload or navigation** switch
it on again the same way — and run `net.js` again if you use it: a page load
wipes both.
Typing: `click` the field, then `type_text` (`fill` does not reach Flutter).
In semantics mode the keyboard can detach a few seconds after a send: click
another element, then the field again.
Read these as tool limits, not app bugs:

- a synthetic `PointerEvent` from a script never reaches Flutter — click by
  uid;
- a page reload wipes caches that live in memory — to cut the network, read
  `<skill>/scripts/net.js` with Read, pass its whole text as
  `evaluate_script`'s function, and set
  `window.__qa.block = true`; `window.__qa.delay = {match, ms}` slows one
  endpoint;
- a toast disappears in about 3 s — screenshot right after the action;
- a tap that seems dead: click something known to work first, then decide.

## Budget

`<budget>` minutes of wall clock and at most 60 browser actions, whichever
comes first. Then stop and report — an unfinished area is a fine result if
you say what you did not reach.

## Evidence

Screenshots with `take_screenshot` → `filePath:
<scratchpad>/charters/<slug>/F-NN-what-it-shows.jpg`, `format: jpeg`,
`quality: 70`, taken when the finding is on screen. A request, a response or
an analytics payload is copied as text into the finding. Console errors:
`list_console_messages`, the relevant lines as text.

## Reply — nothing else

```
Charter <slug> · ended: covered | budget | blocked (<why>)
Reached: <screens and flows you walked, one line>
Not reached: <what the charter named that you did not get to>
Actions: <browser tool calls made>

F-01 · issue | warning · severity 1–5 · <screen or route> · <view>
Expected: <what should happen — from the screen, the spec or common sense>
Actual: <what happened>
Steps: 1. … 2. … 3. … (from the start screen, as a user would do them)
Evidence: <scratchpad>/charters/<slug>/F-01-….jpg; <payload or console text>
```

`issue` = something is wrong for the user; `warning` = polish (copy, a
misaligned element). Severity: 5 critical (data loss, blocked flow, money),
4 high, 3 medium, 2 low, 1 trivial. No preamble, no summary, no advice on
fixes.
