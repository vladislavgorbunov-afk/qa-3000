#!/bin/bash
# Mark navigation milestones in nav-log.jsonl so nav_report.py can compute per-target metrics.
# Usage: nav_mark.sh start <target> <NAV-id|search>   — begin heading to a screen (map route or own search)
#        nav_mark.sh deadend <what>                    — a wrong turn / locked screen / missing content
#        nav_mark.sh human <what>                      — had to ask a person where/how
#        nav_mark.sh done <target> [ok|fail]           — arrived (or gave up)
LOG="${QA_NAV_LOG:-${CLAUDE_PROJECT_DIR:-$PWD}/docs/qa/nav/nav-log.jsonl}"; mkdir -p "$(dirname "$LOG")"
python3 -c 'import json,sys,time; a=sys.argv[1:]; print(json.dumps({"t":time.strftime("%Y-%m-%dT%H:%M:%S"),"mark":a[0],"arg":a[1] if len(a)>1 else "","arg2":a[2] if len(a)>2 else ""}))' "$@" >> "$LOG"
