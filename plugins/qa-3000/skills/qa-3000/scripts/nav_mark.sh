#!/bin/bash
# Mark navigation milestones in nav-log.jsonl so nav_report.py can compute per-target metrics.
# Usage: nav_mark.sh start <target> <NAV-id|search>   — begin heading to a screen (map route or own search)
#        nav_mark.sh deadend <what>                    — a wrong turn / locked screen / missing content
#        nav_mark.sh human <what>                      — had to ask a person where/how
#        nav_mark.sh done <target> [ok|fail]           — arrived (or gave up)
# The log is the app repo's main checkout's docs/qa/nav/nav-log.jsonl (navlog.py), from a worktree too.
exec python3 "$(dirname "$0")/navlog.py" mark "$@"
