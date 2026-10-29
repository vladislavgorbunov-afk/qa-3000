#!/bin/bash
# The qa-3000 plugin's hook. PreToolUse: before an agent's first navigation action (browser click,
# navigate or typing, iOS simulator control, adb input / uiautomator / am start, tap_text_*), put the
# app's navigation map into that agent's context — the main session and each subagent get it once —
# and log every navigation action for the metrics. SessionStart (compact): the map goes back in after
# a compaction. Map: .claude/qa-3000/nav.md in the app repo's main checkout (QA_NAV_MAP overrides it)
# plus its local additions docs/qa/nav/pending.md. No map for this project → the hook does nothing.
exec python3 "$(dirname "$0")/navlog.py" hook
