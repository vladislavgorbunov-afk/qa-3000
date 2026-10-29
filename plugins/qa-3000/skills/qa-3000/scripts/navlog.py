#!/usr/bin/env python3
"""The navigation log and the navigation-map hook of the qa-3000 plugin.

Usage:
    navlog.py mark <start|deadend|human|done> [arg] [arg2]   (nav_mark.sh)
    navlog.py action "<what>"                                (tap_text_*.sh)
    navlog.py path                                           print the log's path
    navlog.py hook                                           (hooks/hooks.json, stdin = hook input)

Everything lands in docs/qa/nav/nav-log.jsonl of the app repo's main checkout (QA_NAV_LOG
overrides it), whether the call comes from the hook, from that checkout or from one of its
worktrees, so a removed worktree takes no metrics with it. Every record carries the Claude
session; the hook's records also carry the subagent that acted, so nav_report.py can keep one
session's main agent apart from the charters running beside it.
"""
import glob, json, os, re, subprocess, sys, time

MARKERS = "/tmp/qa-nav-map-"
# Navigation actions of chrome-devtools and Playwright (Playwright's "browser_" prefix dropped).
WEB_ACTIONS = {"click", "drag", "drop", "fill", "fill_form", "hover", "press_key", "type", "type_text",
               "select_option", "navigate", "navigate_back", "navigate_page", "new_page",
               "handle_dialog", "upload_file", "file_upload"}


def project_root(base=None):
    """The main checkout of the git repository at base (default: the project dir, else the cwd)."""
    base = base or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    try:
        common = subprocess.run(["git", "-C", base, "rev-parse", "--path-format=absolute", "--git-common-dir"],
                                capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        common = ""
    return os.path.dirname(common) if os.path.basename(common) == ".git" else base


def log_path(root=None):
    return os.environ.get("QA_NAV_LOG") or os.path.join(root or project_root(), "docs/qa/nav/nav-log.jsonl")


def append(rec, session=None, root=None):
    rec = {"t": time.strftime("%Y-%m-%dT%H:%M:%S"),
           "session": session or os.environ.get("CLAUDE_CODE_SESSION_ID", ""), **rec}
    path = log_path(root)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a") as f:
        f.write(json.dumps(rec) + "\n")


def hook():
    """PreToolUse: log the navigation action; before an agent's first one, put the map into its context.
    SessionStart (compact): forget which agents got the map, so the next navigation action puts it back."""
    try:
        d = json.load(sys.stdin)
    except Exception:
        return
    sid = d.get("session_id", "x")
    agent = d.get("agent_id") or ""
    if d.get("hook_event_name") == "SessionStart":
        for m in glob.glob(f"{MARKERS}{sid}-*"):
            try: os.remove(m)
            except OSError: pass
        return
    tool = d.get("tool_name", ""); ti = d.get("tool_input", {}) or {}
    web = re.search(r"(?:chrome-devtools__|playwright__browser_)(\w+)$", tool)
    self_logging = False
    if tool == "Bash":
        m = re.search(r"\badb\b[^\n]*\b(input \w+|uiautomator|am start)|\btap_text_(android|ios)\.sh|\baxe (tap|swipe|type)\b",
                      ti.get("command", ""))
        if not m: return
        action = "shell:" + m.group(0)[-60:]
        self_logging = "tap_text_" in m.group(0)   # the helpers log their own taps
    elif web:
        if web.group(1) not in WEB_ACTIONS: return
        action = "web:" + web.group(1) + (":" + str(ti["url"])[:80] if ti.get("url") else "")
    elif tool.startswith("mcp__Claude_Browser__") or tool.startswith("mcp__claude-in-chrome__"):
        a = ti.get("action") or tool.split("__")[-1]
        if a in ("screenshot", "wait", "zoom") or tool.endswith(("read_page", "get_page_text", "find", "read_console_messages",
                                                                 "read_network_requests", "tabs_context", "tabs_context_mcp")): return
        action = "web:" + a + (":" + ti["url"][:80] if ti.get("url") else "")
    elif tool == "mcp__Claude_Code_iOS_Simulator__control":
        a = ti.get("action", "")
        if a in ("screenshot", "attach", "detach"): return
        action = "ios:" + a
    else:
        return
    root = project_root()
    mp = os.environ.get("QA_NAV_MAP") or os.path.join(root, ".claude/qa-3000/nav.md")
    pending = os.path.join(root, "docs/qa/nav/pending.md")
    have = [p for p in (mp, pending) if os.path.isfile(p)]
    if not have: return   # no map for this project: the hook does nothing
    if not self_logging:
        try: append({"action": action, **({"agent": agent} if agent else {})}, session=sid, root=root)
        except Exception: pass
    marker = f"{MARKERS}{sid}-{agent or 'main'}"
    if os.path.exists(marker): return
    open(marker, "w").close()
    txt = "\n\n".join(open(p).read() for p in have)
    ctx = ("QA navigation map — check it BEFORE searching for a screen: use a listed route if one fits "
           "(nav_mark.sh start <target> <NAV-id>), else nav_mark.sh start <target> search. New routes, dead ends "
           "and broken routes go to " + pending + " at the end of the cycle (phase 6).\n\n" + txt[:14000])
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": ctx}}))


def main(argv):
    cmd, args = (argv[0], argv[1:]) if argv else ("", [])
    if cmd == "hook":
        hook()
    elif cmd == "mark" and args:
        append({"mark": args[0], "arg": args[1] if len(args) > 1 else "", "arg2": args[2] if len(args) > 2 else ""})
    elif cmd == "action" and len(args) == 1:
        append({"action": args[0]})
    elif cmd == "path":
        print(log_path())
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
