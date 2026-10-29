#!/bin/bash
# Tap an on-screen element by its visible label (Flutter semantics -> accessibility content-desc/text).
# Usage: tap_text_android.sh "<label>" [serial]   |   tap_text_android.sh --list [serial]
# Which label wins: tap_match.py. Exit 0 = tapped (prints label + centre), 2 = not found or not
# tapped (prints why and what is visible), 3 = no device, 4 = the UI dump or the tap failed.
set -u
DIR=$(cd "$(dirname "$0")" && pwd)
Q="${1:-}"; SER="${2:-${ANDROID_SERIAL:-}}"
ADB=(adb); [ -n "$SER" ] && ADB=(adb -s "$SER")
"${ADB[@]}" get-state >/dev/null 2>&1 || { echo "no device"; exit 3; }
# A fresh dump every time: a failed one must not leave the previous screen's file to be read.
"${ADB[@]}" shell rm -f /sdcard/qa_ui.xml >/dev/null 2>&1
OUT=$("${ADB[@]}" shell uiautomator dump /sdcard/qa_ui.xml 2>&1)
XML=$("${ADB[@]}" exec-out cat /sdcard/qa_ui.xml 2>/dev/null)
case "$XML" in *"<hierarchy"*) ;; *) echo "uiautomator dump failed: $OUT"; exit 4;; esac
RES=$(printf '%s' "$XML" | python3 "$DIR/tap_match.py" android "$Q"); rc=$?
echo "$RES"
[ $rc -ne 0 ] && exit $rc
{ [ -z "$Q" ] || [ "$Q" = "--list" ]; } && exit 0
XY=$(printf '%s\n' "$RES" | sed -n 's/^TAP \([0-9]*\),\([0-9]*\).*/\1 \2/p')
# shellcheck disable=SC2086
"${ADB[@]}" shell input tap $XY || { echo "tap failed"; exit 4; }
python3 "$DIR/navlog.py" action "android:tap_text $Q"
