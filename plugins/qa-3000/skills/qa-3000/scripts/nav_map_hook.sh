#!/bin/bash
# PreToolUse hook of the qa plugin: before the first navigation action of a session (browser
# click/navigate, iOS simulator control, adb input / uiautomator / am start, tap_text_*), put the
# app's navigation map into the model's context, and log every navigation action for the metrics.
# Map: .claude/qa-3000/nav.md in the project (QA_NAV_MAP overrides it) plus the project's local
# additions docs/qa/nav/pending.md. No map for this project → the hook does nothing.
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
MAP="${QA_NAV_MAP:-$PROJ/.claude/qa-3000/nav.md}"
PENDING="$PROJ/docs/qa/nav/pending.md"
LOG="${QA_NAV_LOG:-$PROJ/docs/qa/nav/nav-log.jsonl}"
IN=$(cat)
python3 - "$MAP" "$PENDING" "$LOG" "$IN" <<'PY'
import sys, json, os, re, time
mp, pending, log, raw = sys.argv[1:5]
have = [p for p in (mp, pending) if os.path.isfile(p)]
if not have: sys.exit(0)
try: d = json.loads(raw)
except Exception: sys.exit(0)
tool = d.get("tool_name", ""); ti = d.get("tool_input", {}) or {}; sid = d.get("session_id", "x")
if tool == "Bash":
    cmd = ti.get("command", "")
    m = re.search(r"\badb\b[^\n]*\b(input \w+|uiautomator|am start)|\btap_text_(android|ios)\.sh|\baxe (tap|swipe|type)\b", cmd)
    if not m: sys.exit(0)
    action = "shell:" + m.group(0)[-60:]
    self_logging = "tap_text_" in m.group(0)   # the helpers log their own taps
elif tool.startswith("mcp__Claude_Browser__") or tool.startswith("mcp__claude-in-chrome__"):
    a = ti.get("action") or tool.split("__")[-1]
    if a in ("screenshot", "wait", "zoom") or tool.endswith(("read_page", "get_page_text", "find", "read_console_messages", "read_network_requests", "tabs_context", "tabs_context_mcp")): sys.exit(0)
    action = "web:" + a + (":" + ti["url"][:80] if ti.get("url") else ""); self_logging = False
elif tool == "mcp__Claude_Code_iOS_Simulator__control":
    a = ti.get("action", "")
    if a in ("screenshot", "attach", "detach"): sys.exit(0)
    action = "ios:" + a; self_logging = False
else:
    sys.exit(0)
if not self_logging:
    try:
        os.makedirs(os.path.dirname(log), exist_ok=True)
        with open(log, "a") as f: f.write(json.dumps({"t": time.strftime("%Y-%m-%dT%H:%M:%S"), "session": sid, "action": action}) + "\n")
    except Exception: pass
marker = f"/tmp/qa-nav-map-{sid}"
if os.path.exists(marker): sys.exit(0)
open(marker, "w").close()
txt = "\n\n".join(open(p).read() for p in have)
ctx = ("QA navigation map — check it BEFORE searching for a screen: use a listed route if one fits "
       "(nav_mark.sh start <target> <NAV-id>), else nav_mark.sh start <target> search. New routes, dead ends "
       "and broken routes go to " + pending + " at the end of the cycle (phase 6).\n\n" + txt[:14000])
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": ctx}}))
PY
