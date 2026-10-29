#!/usr/bin/env python3
"""Per-target navigation metrics from nav-log.jsonl: actions, seconds, dead ends, human asks, map hit.

Usage: nav_report.py [--session <id> | --all] [log]
Default: this Claude session only (CLAUDE_CODE_SESSION_ID), so earlier cycles stay out. Actions a
subagent took (charters in their own pages) carry its agent id and are never counted.
"""
import json, sys, os
from datetime import datetime
import navlog

args = sys.argv[1:]
session = os.environ.get("CLAUDE_CODE_SESSION_ID")
if "--all" in args:
    args.remove("--all"); session = None
if "--session" in args:
    i = args.index("--session"); session = args[i + 1]; del args[i:i + 2]
log = args[0] if args else navlog.log_path()
rows = [json.loads(l) for l in open(log) if l.strip()]
rows = [r for r in rows if not r.get("agent") and (session is None or r.get("session") == session)]
ts = lambda r: datetime.fromisoformat(r["t"])
out, open_by_session = [], {}
for r in rows:
    m, s = r.get("mark"), r.get("session", "")
    cur = open_by_session.get(s)
    if m == "start":
        open_by_session[s] = {"target": r["arg"], "route": r["arg2"] or "search", "t0": ts(r), "actions": 0, "deadends": 0, "human": 0}
    elif cur is None:
        continue
    elif m is None:
        cur["actions"] += 1
    elif m == "deadend":
        cur["deadends"] += 1
    elif m == "human":
        cur["human"] += 1
    elif m == "done":
        cur["sec"] = int((ts(r) - cur["t0"]).total_seconds()); cur["result"] = r["arg2"] or "ok"
        out.append(cur); open_by_session[s] = None
if session:
    print(f"session {session}")
print(f"{'target':28} {'route':24} {'act':>4} {'sec':>5} {'dead':>4} {'ask':>3} result")
for o in out:
    print(f"{o['target'][:28]:28} {o['route'][:24]:24} {o['actions']:>4} {o['sec']:>5} {o['deadends']:>4} {o['human']:>3} {o['result']}")
if out:
    hit = sum(o['route'] != 'search' for o in out) / len(out)
    med = sorted(o['sec'] for o in out)[len(out) // 2]
    print(f"\ntargets {len(out)} · map hit {hit:.0%} · median sec {med} · dead ends {sum(o['deadends'] for o in out)} · human asks {sum(o['human'] for o in out)}")
