# Filing bugs in Jira

The host, cloud id, project, bug fields and components are in profile → Jira.
Below, `<host>`, `<PROJECT>` and the field roles stand for them: three in
every profile, plus *additional details* when the profile maps it.

When profile → Jira has the **Overrides:** line that turns on the
dev-process-toolkit module (a Jira project shared between repositories and
guarded by that toolkit's hooks), `jira-dev-process-toolkit.md` decides who
creates a bug and how every write goes; the shape, the priority and the
attachments below still apply.

## The shape of one bug

| Field | Value |
|---|---|
| Issue type | the profile's bug type (usually `Bug`) |
| Summary | `[FE]` / `[BE]` + area + the defect in one line: `[FE] Library: the header shows "0 items" when loading fails` |
| Priority | what a real user loses and what it costs the business — § Priority below |
| Components | by the profile's rule; unclear ownership: ask at Stop 2 |
| *what's wrong* | 1–3 sentences: what the user sees (for analytics: what is sent), then the cause with a source file reference |
| *how it should be* | 1–2 sentences |
| *steps* | The steps you replayed in phase 3c, unchanged, **in English on every line**: precondition paragraph (account, build, platform, any forced condition, `Reproduced on web, stage, main @ <sha>.` or `Reproduced by <person> on <device>.`), ordered list of steps, `Actual: … (screenshot 2)` — for analytics the payload itself — and `Expected: …` |
| *additional details* | Only when the profile maps this role: the cause with file references, the console / logcat lines as text, related tickets. Then *what's wrong* keeps to what the user sees and leaves the cause here |
| Link | `Relates` → the story it was found under |
| Attachments | **Required when the defect is visible**: the screenshots from the 3c replay, of what the user sees; a pair when a condition triggers it (before / after, normal / large text); an error symptom → the console lines as an image. A person's photo or video goes first. **A video** too when the defect happens in time (a flash, a double request, a race, a missing busy state): the 3c replay as H.264 `.mp4` (`live-web.md` → Video), named `video-<what-it-shows>.mp4` and named in Actual. **Not needed** when the evidence is text (analytics payload, response body) — it goes into Steps verbatim. Rename to what they show (`1-offline-fresh.jpg`, `2-offline-expired-error.jpg`) and refer to them from Steps as "(screenshot 1)" |

Everything in English, compact — no "Impact" / "Scenarios" / "Artifacts"
sections. The steps are English **including the UI labels**: a label is quoted
exactly as the app shows it, then its English meaning in parentheses. Wrong:
`Home → "Einstellungen" → "Konto löschen" → "Abbrechen"`. Right:
`Home → tap "Einstellungen" (Settings) → tap "Konto löschen" (Delete account) → tap "Abbrechen" (Cancel)`.
Before the write, read the steps once for any word that is not English and
translate it. When the profile maps the roles to custom fields, those are
ADF documents, not strings, and the system Description stays empty; when it
maps them to sections of the Description, write one ADF document with a
heading per role.

## Priority

Priority is what a real user loses and what that costs the business — not
how wrong the code is, how hard the bug was to find, or how many layers it
touches. A real user is someone on production, on an ordinary device and
network, using the app as it is meant to be used.

**First: can a real user notice it, now or later?** When only a tool shows
the defect and nothing follows from it for the user, it is `Low` or
`Lowest` — always, whatever it breaks in the code:

- analytics off the money paths: an event missing, doubled or misnamed, a
  wrong property;
- a console or logcat error, a non-fatal in the crash reporter;
- an extra or slow request the screen does not show;
- a fallback, cache or retry that is wrong while the screen stays right and
  nothing is lost;
- a debug or QA-only surface production cannot reach.

`Low` when it skews a number the business decides on (the registration
funnel, activation, retention); `Lowest` otherwise.

Three kinds of quiet defect are not capped — they take the priority of what
they cost:

- **Harm that shows later** — rate it as the visible defect it turns into,
  reach rule included: a purchase request sent twice (a double charge),
  progress kept only in the cache (gone on another device), a payment SDK
  that fails to start (the next purchase is not granted), a missing paywall
  fallback (an empty paywall while the provider is down).
- **Money data** — purchase, paywall and attribution events missing or
  wrong: `Medium`; `High` when they stop for every user, since ad spend and
  pricing are decided on them.
- **Security and privacy** — a token, a password or another person's data
  in a log, an analytics payload or a response; a debug surface on
  production that exposes data or switches the backend: `High`; `Highest`
  when it opens someone else's account or payment.

**A defect the user sees** takes its priority from the path it is on.
Profile → Jira names the app's money paths (paywall, purchase, restore,
sign-up, sign-in, anything bought) and its core flow (what people open the
app for); a profile without them: ask at Stop 1 and add them to it.

| Priority | In normal use |
|---|---|
| `Highest` | Money or the core flow stops: no purchase, a purchase not granted, no sign-up or sign-in, a crash or a hang at launch or in the core flow, lost progress |
| `High` | A money or core path is broken or misleading, with no way around it: a paywall link that does nothing, a wrong price or trial length, a funnel the user cannot get back to, a whole screen or the app in the wrong language |
| `Medium` | Visible and in the way, but with a way around it, or off the money and core paths |
| `Low` | Visible but minor, off the money paths: copy, a single untranslated string, a layout that stays usable |
| `Lowest` | Cosmetics: spacing, alignment, an icon a few pixels off |

Then reach, at every level: one level down when the defect needs a rare
real condition (a backend outage, a lost network where the feature does not
promise to work offline, one old OS version); `Low` at most when only a
response the backend never sends shows it (a malformed body, an empty
`200`).

Not a reason to raise it: a regression, a charter's severity, a
review candidate's `High`, the story's own priority. The Stop 2 draft gives
every priority its reason in a few words — `Low — invisible: analytics
only`, `High — paywall, every iOS user`.

## Create → fill → link

**With the Atlassian MCP:** `createJiraIssue` (`projectKey: <PROJECT>`,
`issueTypeName`, `summary`, `additional_fields: {priority: {name}, components: [{name}]}`)
→ `editJiraIssue` with one ADF doc per role in the profile's fields →
`createIssueLink` (`type: Relates`, `inwardIssue: <new>`, `outwardIssue: <story>`).

**Without it** (never with the dev-process-toolkit module on): REST from a Jira tab that is already logged in (chrome-devtools
`evaluate_script`, same origin, cookie auth). Two calls, because
`evaluate_script` rejects long functions and anything with backticks or an
`await` inside an expression ("missing ) after argument list"):

```js
// call 1 — build the payloads on window (⟦…⟧ marks inline code)
() => {
  window.__jira = { project: '<PROJECT>', type: '<bug type>',
    what: '<whats-wrong field>', how: '<how-it-should-be field>', steps: '<steps field>',
    more: null };  // profile → Jira; more = the additional-details field, or null
  const txt = s => s.split(/(⟦[^⟧]+⟧)/).filter(Boolean).map(p => p.startsWith('⟦')
    ? { type: 'text', text: p.slice(1, -1), marks: [{ type: 'code' }] } : { type: 'text', text: p });
  const P = s => ({ type: 'paragraph', content: txt(s) });
  const OL = items => ({ type: 'orderedList', content: items.map(i => ({ type: 'listItem', content: [P(i)] })) });
  const doc = (...c) => ({ type: 'doc', version: 1, content: c });
  window.__bugs = [{   // example shape — values are illustrative
    link: '<STORY>', priority: 'Low', components: ['<component>'],
    summary: '[FE] Library: the header shows "0 items" when loading fails',
    w: doc(P('When a list fails to load, its header still renders "0 items" above the error text (⟦library_header.dart⟧).')),
    h: doc(P('On a load error the counts line is hidden.')),
    s: doc(P('Precondition: account with access to the library. Reproduced on web, stage, main @ <sha>.'),
           OL(['Open the library → a list: the header shows its count (screenshot 1).', 'Go back and cut the network.', 'Open a list not opened in this session.']),
           P('Actual: "0 items" above the error (screenshot 2).'), P('Expected: only the name and the error.')),
    d: null,   // with J.more: doc(P('Cause: …'), P('Related: …'))
  }];
  return window.__bugs.length;
}
```

```js
// call 2 — create, fill, link; returns the new keys
async () => {
  const J = window.__jira;
  const H = { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Atlassian-Token': 'no-check' };
  const out = [];
  for (const b of window.__bugs) {
    if (b.key) { out.push({ key: b.key, skipped: true }); continue; }
    const create = { fields: { project: { key: J.project }, issuetype: { name: J.type }, summary: b.summary,
      priority: { name: b.priority }, components: b.components.map(n => ({ name: n })) } };
    const r1 = await fetch('/rest/api/3/issue', { method: 'POST', headers: H, body: JSON.stringify(create) });
    const j1 = await r1.json();
    if (!j1.key) { out.push({ error: r1.status, body: j1 }); return out; }
    b.key = j1.key;
    const edit = { fields: { [J.what]: b.w, [J.how]: b.h, [J.steps]: b.s } };
    if (J.more) edit.fields[J.more] = b.d;
    const r2 = await fetch('/rest/api/3/issue/' + b.key, { method: 'PUT', headers: H, body: JSON.stringify(edit) });
    const link = { type: { name: 'Relates' }, inwardIssue: { key: b.key }, outwardIssue: { key: b.link } };
    const r3 = await fetch('/rest/api/3/issueLink', { method: 'POST', headers: H, body: JSON.stringify(link) });
    out.push({ key: b.key, edit: r2.status, link: r3.status });
  }
  return out;
}
```

`edit` must be `204` and `link` `201`; anything else — read the body before
retrying, the issue already exists (the `b.key` guard stops a duplicate). When
the profile puts the roles into the Description instead, send one
`description` doc in `edit`.

## Attachments without base64

The MCP cannot attach files. Upload from disk through a file input instead of
pushing base64 through `evaluate_script`:

1. chrome-devtools `new_page` → `https://<host>/robots.txt`
   (same origin as Jira, so the session cookie applies; the page is tiny, so its
   snapshot is two lines).
2. `evaluate_script`:
   `() => { document.body.innerHTML = '<input type="file" id="up" multiple aria-label="upload">'; return true; }`
3. `take_snapshot` → the `button "upload"` uid → `upload_file` with that uid and
   `filePaths: [...]` (an array, even for one file).
4. `evaluate_script`:

```js
async () => {
  const plan = [                                        // key, local name, name in Jira
    ['<KEY>', '31-list-online.jpg', '1-list-online-count.jpg'],
    ['<KEY>', '32-list-offline-error.jpg', '2-list-offline-error-0-items.jpg'],
  ];
  const byName = {};
  for (const f of document.getElementById('up').files) byName[f.name] = f;
  const out = [];
  for (const [key, src, name] of plan) {
    const fd = new FormData();
    fd.append('file', new File([byName[src]], name, { type: byName[src].type }));
    const r = await fetch('/rest/api/3/issue/' + key + '/attachments',
      { method: 'POST', headers: { 'X-Atlassian-Token': 'no-check' }, body: fd });
    out.push({ key, name, status: r.status });
  }
  return out;
}
```

Every status must be `200`. Then re-read the issue
(`/rest/api/3/issue/<key>?fields=attachment,issuelinks,<what's wrong field>[,<additional details field>]`)
and confirm the attachment names, the link and the filled fields before reporting the
key to the user. A visible defect with an empty `attachment` list is not done —
upload before reporting it.

A photo from the user's phone (`images/N.jpg`, often 6–8 MB) goes through
`sips -Z 2400 -s formatOptions 80` first.
