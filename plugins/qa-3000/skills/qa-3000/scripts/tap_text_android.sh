#!/bin/bash
# Tap an on-screen element by its visible label (Flutter semantics -> accessibility content-desc/text).
# Usage: tap_text_android.sh "<label substring>" [serial]   |   tap_text_android.sh --list [serial]
# Exit 0 = tapped (prints label + bounds), 2 = not found (prints visible labels), 3 = no device.
set -u
Q="${1:-}"; SER="${2:-${ANDROID_SERIAL:-}}"
ADB=(adb); [ -n "$SER" ] && ADB=(adb -s "$SER")
"${ADB[@]}" get-state >/dev/null 2>&1 || { echo "no device"; exit 3; }
"${ADB[@]}" shell uiautomator dump /sdcard/qa_ui.xml >/dev/null 2>&1
XML=$("${ADB[@]}" exec-out cat /sdcard/qa_ui.xml 2>/dev/null)
python3 - "$Q" <<PY "$XML"
import sys, re, html
q = sys.argv[1]; xml = sys.argv[2] if len(sys.argv) > 2 else ""
nodes = []
for m in re.finditer(r'<node [^>]*>', xml):
    n = m.group(0)
    lab = html.unescape((re.search(r'content-desc="([^"]*)"', n) or [None, ''])[1] or (re.search(r' text="([^"]*)"', n) or [None, ''])[1])
    b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
    if lab.strip() and b:
        x1, y1, x2, y2 = map(int, b.groups()); nodes.append((lab.replace('\n', ' | '), (x1 + x2)//2, (y1 + y2)//2))
if q == '--list' or not q:
    for l, x, y in nodes: print(f"{x},{y}\t{l}")
    sys.exit(0)
ql = q.lower()
hits = [n for n in nodes if n[0].lower() == ql] or [n for n in nodes if ql in n[0].lower()]
if not hits:
    print("NOT FOUND:", q); print("visible:", " ; ".join(l for l, _, _ in nodes)); sys.exit(2)
l, x, y = hits[0]; print(f"TAP {x},{y}\t{l}")
open('${TMPDIR:-/tmp}/qa_tap_xy', 'w').write(f"{x} {y}")
PY
rc=$?; [ $rc -ne 0 ] && exit $rc
[ "$Q" = "--list" ] || [ -z "$Q" ] && exit 0
read X Y < ${TMPDIR:-/tmp}/qa_tap_xy; "${ADB[@]}" shell input tap "$X" "$Y"
LOG="${QA_NAV_LOG:-${CLAUDE_PROJECT_DIR:-$PWD}/docs/qa/nav/nav-log.jsonl}"; mkdir -p "$(dirname "$LOG")"
python3 -c 'import json,sys,time; print(json.dumps({"t":time.strftime("%Y-%m-%dT%H:%M:%S"),"action":"android:tap_text "+sys.argv[1]}))' "$Q" >> "$LOG"
