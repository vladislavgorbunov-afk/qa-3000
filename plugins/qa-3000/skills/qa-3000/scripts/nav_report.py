#!/usr/bin/env python3
"""Per-target navigation metrics from nav-log.jsonl: actions, seconds, dead ends, human asks, map hit."""
import json, sys, os
from datetime import datetime
log = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()), "docs/qa/nav/nav-log.jsonl")
rows = [json.loads(l) for l in open(log) if l.strip()]
ts = lambda r: datetime.fromisoformat(r["t"])
out, cur = [], None
for r in rows:
    m = r.get("mark")
    if m == "start":
        cur = {"target": r["arg"], "route": r["arg2"] or "search", "t0": ts(r), "actions": 0, "deadends": 0, "human": 0}
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
        out.append(cur); cur = None
print(f"{'target':28} {'route':24} {'act':>4} {'sec':>5} {'dead':>4} {'ask':>3} result")
for o in out:
    print(f"{o['target'][:28]:28} {o['route'][:24]:24} {o['actions']:>4} {o['sec']:>5} {o['deadends']:>4} {o['human']:>3} {o['result']}")
if out:
    hit = sum(o['route'] != 'search' for o in out) / len(out)
    med = sorted(o['sec'] for o in out)[len(out) // 2]
    print(f"\ntargets {len(out)} · map hit {hit:.0%} · median sec {med} · dead ends {sum(o['deadends'] for o in out)} · human asks {sum(o['human'] for o in out)}")
