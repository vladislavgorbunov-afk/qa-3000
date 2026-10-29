# Test documentation formats

Three files per QA cycle, all under `docs/qa/` (kept out of git by
`.git/info/exclude` → `docs/qa/`; add the line if it is missing, never touch
`.gitignore`). `<KEY>` is the story, or both for two (the form in profile →
Repo and specs).

## `docs/qa/<KEY>.md` — impact + checklist + results

In the report language (`SKILL.md` → Report language): the example below is
the English default; another language takes its headings and phrases from
§ Report language at the end of this file. Short: the reference is a
3.5 KB Impact comment plus a 3.5 KB QA test plan, not a dump.

```markdown
# APP-325 — saved items

Tested: `main` @ `94db324` (PR #153), merged 2026-09-22. Report with screenshots: <artifact link>

## Impact
### What changes for the user           — 3–6 bullets, user-visible only
### Ticket breakdown                    — table: ticket · status · what shipped
### AC against what shipped             — only the divergences, table
### Verification                        — numbers: unit/widget, analyze, e2e regression (passed / failed / skipped, minutes), live run; for a bug, one row per bug case: its regression test `file:line`, red on the pre-fix ref (first error line), green on the fix, and its branch if this cycle wrote it
### Defects found                       — reproduced only, laid out by priority as SKILL.md → Phase 4 says; each says where it was reproduced (web @ ref / by a person) and ends with → **<bug key>** once filed
### Rejected, with the reason           — every rejected lead, grouped: tool artefact · environment · by design (where it says so) · stand data; one line each, with its source (charter slug, R-NN, audit). A candidate that did not reproduce is not here: it is an open question
### Production risks (not checked)      — environment leads the stage cannot show for real but the app would handle badly in production too
### Known — do not file                 — by-design and decided-not-a-bug items

## Manual test plan
Build, account (without the password), status legend:
`[x] ✅` pass · `[x] ❌` defect reproduces · `[ ] ◐` partly · `[ ]` not run ·
`[ ] N/A` stage data cannot reach it (say why)

### 1. <area>
- [ ] One line: the check, then **what failure to look for**.
  - result line, added after the run
```

Rules for the checklist: one checkbox = one line; every item names the failure
it hunts; unit / widget / static checks are CI's job and stay out; "decide X"
items are tasks, not checks — they go to an owners table; ~25 checks, not 100.
A result a person reports closes its item with "checked by hand — <who>,
<date>".

After the checklist, the charters (`reference/charters.md`), written in
phase 2 and closed when each one replies:

```markdown
## Charters
| Slug | Setting | Start | Account | Charter | Outcome |
|---|---|---|---|---|---|
| saved-skeptic | numbers and copy | NAV-saved | qa+1@… | Starting at Saved, save and unsave three items; check every count and label against the rest of the app | budget · 3 findings: 1 kept (D-04), 2 rejected · not reached: the share sheet |
```

After the checklist, two tables:

```markdown
## Needs a human
| Check | Why not on web | Device, setting, build | Steps (≤ 3) | Where to look |
|---|---|---|---|---|
| The sheet stays below the status bar | web has no safe area | iPhone with Dynamic Island, Larger Text max, stage ≥ <build> | Library → a list → an item | top of the sheet: handle and close button below the clock |

## Decisions and access
| What | Who |
|---|---|

## Open questions
1. The question — to whom. Findings "by code, not reproduced — tried: …" go here too.
```

## `docs/qa/<KEY>-test-cases.md` — atomic cases (TestRail mirror)

In English — it mirrors TestRail and quotes UI copy verbatim: the English
string, plus the localization key when the case runs in another locale.

```markdown
# APP-325 Saved items — test cases

Smoke set: S-01, S-04, S-07 (★ below). TestRail: <section link, once pushed>

## Browsing
### S-01 ★ Saved tab lists every saved item — <C-id once pushed>
Precondition: account with three saved items, logged in.
1. Open the Saved tab.
2. Scroll to the end of the list.
Expected: three cards, each with a cover and a title, newest first.
```

Case rules: **one assertion per case**, **at most three steps**, the expected
result only after the last step. The precondition is only the state the
tester sets up before the steps (`Logged out.`, `On the code-entry screen.`,
`Account with the premium entitlement.`): no shared header, no
environment, build, library versions or dates — they go stale and tell the
tester nothing.
Ids `<PREFIX>-NN` are stable — checklist items, the tests audit and bugs refer
to them. Mark the **smoke** set (★): the cases whose failure blocks a release —
typically 10–15 % of the cases.

## `docs/qa/<KEY>-tests.md` — automated tests audit

Written by the tests-audit subagent, format in `prompts/tests-audit.md`.

## TestRail

Only the ★ smoke cases go to TestRail; the full set stays in the md file.
Profile → TestRail "none" turns this step off.

- Project and suite: profile → TestRail. The template, type and priority ids
  below are TestRail's defaults; the profile names any that differ on its
  instance, and the custom fields that are not enabled.
- Destination: a subsection named `<Feature> (<KEY>)` — e.g.
  `Saved items (APP-325)` — inside the feature's existing top-level section
  (`<skill>/scripts/testrail.py sections <project_id> <suite_id>`). Create it
  when missing (`testrail.py add-section <project_id> <suite_id> "<name>"
  <parent_id>`). A cross-cutting feature with no section of its own gets a
  top-level `<Feature> (<KEY>)`.
- One JSON array, one object per ★ case:
  `{"title": "S-01 …", "template_id": 2, "type_id": 6, "priority_id": 2, "custom_preconds": "…", "custom_steps_separated": [{"content": "…", "expected": ""}, {"content": "…", "expected": "…"}]}`
  — `template_id 2` is "Test Case (Steps)"; `type_id 6` Functional for
  behaviour the change introduces, `9` Regression for existing behaviour it
  must not break; `priority_id` as the profile says; the case's precondition
  in `custom_preconds`; `expected` only on the last step; leave out the
  fields the profile says are not enabled. Set `refs` to the story key only
  when profile → TestRail asks for Jira references on cases; never write the
  key into a precondition.
- Push: `python3 <skill>/scripts/testrail.py add-cases <section_id> <file.json>`
  with the credentials in `TESTRAIL_URL`, `TESTRAIL_USER` and
  `TESTRAIL_API_KEY` (or a JSON file `{"base_url", "email", "api_key"}` named
  by `TESTRAIL_CONFIG`). No credentials: hand the md over. Afterwards write
  each `C<id>` link next to its case in the md.

## Report language

`SKILL.md` → Report language picks it. English is the default and the
examples in this file and in `templates/report.html` use it. A report in
another language replaces every heading and fixed phrase with its
translation — Russian below, any other translated from the English column the
same way — keeps the same order and structure, and sets `<html lang>` on the
page.

| English (default) | Russian |
|---|---|
| Tested: `<ref>` … merged … Report with screenshots: | Проверено: `<ref>` … влит … Отчёт со скриншотами: |
| What changes for the user | Что меняется для пользователя |
| Ticket breakdown | Разбивка по тикетам |
| AC against what shipped | AC против того, что уехало |
| Verification | Верификация |
| Defects found | Найденные дефекты |
| Rejected, with the reason — tool artefact · environment · by design · stand data | Отклонено по причине — артефакт инструмента · окружение · по задумке · данные стенда |
| Production risks (not checked) | Риски для прода (не проверено) |
| Known — do not file | Известное — не заводить |
| Manual test plan · Build, account | План ручного тестирования · Сборка, аккаунт |
| legend: pass · defect reproduces · partial · not run · stage cannot reach it (why) | легенда: прошло · дефект воспроизводится · частично · не запускалось · стенд не даёт (почему) |
| Charters: Slug · Setting · Start · Account · Charter · Outcome | Чартеры: Slug · Установка · Старт · Аккаунт · Чартер · Итог |
| Needs a human: Check · Why not on web · Device, setting, build · Steps (≤ 3) · Where to look | Нужен человек: Проверка · Почему не на вебе · Устройство, настройка, сборка · Шаги (≤ 3) · Где смотреть |
| Decisions and access: What · Who | Решения и доступы: Что · Кто |
| Open questions | Открытые вопросы |
| by code, not reproduced — tried: … | по коду, не воспроизведено — пробовал: … |
| checked by hand — <who>, <date> | проверено вручную — <кто>, <дата> |
| (delta) | (дельта) |
| HTML: run report · Path I walked · Defects — … · Checked and clean | HTML: отчёт о прогоне · Путь, который я прошёл · Дефекты — … · Проверено и чисто |
| passed (tag) | пройдено (тег) |

The tests audit (`<KEY>-tests.md`) follows the same language: its brief's
language slot takes the report language.
