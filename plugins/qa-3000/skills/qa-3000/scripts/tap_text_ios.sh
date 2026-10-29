#!/bin/bash
# Tap an iOS simulator element by its visible label (Flutter semantics -> iOS accessibility), via AXe.
# Usage: tap_text_ios.sh "<label>" [udid]   |   tap_text_ios.sh --list [udid]
# Full `axe describe-ui` fails on Xcode 27 / DeviceHub, so the screen is scanned point by point
# (`describe-ui --point`): a 60 pt grid first; a label it does not settle (missing, ambiguous, or only
# inside a merged label) costs a second pass on a 30 pt grid between those points, which catches
# anything at least 30 pt across. `--list` runs both passes. Which label wins: tap_match.py.
# Exit 0 = tapped, 2 = not found or not tapped (prints why), 3 = no AXe / simulator, 4 = the tap failed.
set -u
DIR=$(cd "$(dirname "$0")" && pwd)
Q="${1:-}"; U="${2:-${IOS_UDID:-$(xcrun simctl list devices booted | grep -m1 -o '[0-9A-F-]\{36\}')}}"
command -v axe >/dev/null || { echo "AXe missing: brew install cameroncooke/axe/axe"; exit 3; }
[ -n "$U" ] || { echo "no booted simulator"; exit 3; }
python3 - "$Q" "$U" "$DIR" <<'PY'
import sys, json, subprocess, concurrent.futures as cf
q, u = sys.argv[1], sys.argv[2]
sys.path.insert(0, sys.argv[3]); import tap_match
def at(p):
    r = subprocess.run(["axe", "describe-ui", "--udid", u, "--point", p], capture_output=True, text=True)
    try: return json.loads(r.stdout)
    except Exception: return None
W, H = 440, 956                     # covers every current iPhone in points
seen = {}
def scan(step):
    pts = [f"{x},{y}" for y in range(step // 2, H, step) for x in range(step // 2, W, step)]   # 30 pt: 15, 45, … — none on the 60 pt grid
    with cf.ThreadPoolExecutor(12) as ex:
        for d in ex.map(at, pts):
            if not d: continue
            lab = (d.get("AXLabel") or d.get("AXValue") or "").strip(); f = d.get("frame") or {}
            if lab and f: seen[(lab, f["x"], f["y"])] = (lab.replace("\n", " | "), f["x"] + f["width"] / 2, f["y"] + f["height"] / 2, f["width"] * f["height"])
nodes = lambda: sorted(seen.values(), key=lambda n: (n[2], n[1]))
scan(60)
if q in ("", "--list") or tap_match.pick(nodes(), q)[0] is None:
    scan(30)
if q in ("", "--list"):
    sys.exit(tap_match.run(nodes(), q))
n, why = tap_match.pick(nodes(), q)
if not n:
    print(why); sys.exit(2)
r = subprocess.run(["axe", "tap", "-x", str(round(n[1])), "-y", str(round(n[2])), "--udid", u], capture_output=True, text=True)
if r.returncode:
    print("tap failed:", (r.stderr or r.stdout).strip()); sys.exit(4)
print(f"TAP {n[1]:.0f},{n[2]:.0f}\t{n[0]}")
PY
rc=$?
if [ $rc -eq 0 ] && [ -n "$Q" ] && [ "$Q" != "--list" ]; then
  python3 "$DIR/navlog.py" action "ios:tap_text $Q"
fi
exit $rc
