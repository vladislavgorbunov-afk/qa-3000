#!/bin/bash
# Tap an iOS simulator element by its visible label (Flutter semantics -> iOS accessibility), via AXe.
# Usage: tap_text_ios.sh "<label substring>" [udid]   |   tap_text_ios.sh --list [udid]
# Full `axe describe-ui` fails on Xcode 27 / DeviceHub, so the screen is scanned point by point
# (`describe-ui --point`) and the matching element's centre is tapped. Exit 2 = not found, 3 = no AXe/sim.
set -u
Q="${1:-}"; U="${2:-${IOS_UDID:-$(xcrun simctl list devices booted | grep -m1 -o '[0-9A-F-]\{36\}')}}"
command -v axe >/dev/null || { echo "AXe missing: brew install cameroncooke/axe/axe"; exit 3; }
[ -n "$U" ] || { echo "no booted simulator"; exit 3; }
python3 - "$Q" "$U" <<'PY'
import sys, json, subprocess, concurrent.futures as cf
q, u = sys.argv[1], sys.argv[2]
def at(p):
    r = subprocess.run(["axe", "describe-ui", "--udid", u, "--point", p], capture_output=True, text=True)
    try: return json.loads(r.stdout)
    except Exception: return None
W, H, STEP = 440, 956, 60           # covers every current iPhone in points
pts = [f"{x},{y}" for y in range(STEP // 2, H, STEP) for x in range(STEP // 2, W, STEP)]
seen = {}
with cf.ThreadPoolExecutor(12) as ex:
    for d in ex.map(at, pts):
        if not d: continue
        lab = (d.get("AXLabel") or d.get("AXValue") or "").strip(); f = d.get("frame") or {}
        if lab and f: seen[(lab, f["x"], f["y"])] = (lab.replace("\n", " | "), f["x"] + f["width"] / 2, f["y"] + f["height"] / 2)
nodes = sorted(seen.values(), key=lambda n: (n[2], n[1]))
if q in ("", "--list"):
    for l, x, y in nodes: print(f"{x:.0f},{y:.0f}\t{l}")
    sys.exit(0)
ql = q.lower()
hits = [n for n in nodes if n[0].lower() == ql] or [n for n in nodes if ql in n[0].lower()]
if not hits:
    print("NOT FOUND:", q); print("visible:", " ; ".join(n[0] for n in nodes)); sys.exit(2)
l, x, y = hits[0]
subprocess.run(["axe", "tap", "-x", str(round(x)), "-y", str(round(y)), "--udid", u], capture_output=True)
print(f"TAP {x:.0f},{y:.0f}\t{l}")
PY
rc=$?
if [ $rc -eq 0 ] && [ -n "$Q" ] && [ "$Q" != "--list" ]; then
  LOG="${QA_NAV_LOG:-${CLAUDE_PROJECT_DIR:-.}/docs/qa/nav/nav-log.jsonl}"; mkdir -p "$(dirname "$LOG")"
  python3 -c 'import json,sys,time; print(json.dumps({"t":time.strftime("%Y-%m-%dT%H:%M:%S"),"action":"ios:tap_text "+sys.argv[1]}))' "$Q" >> "$LOG"
fi
exit $rc
