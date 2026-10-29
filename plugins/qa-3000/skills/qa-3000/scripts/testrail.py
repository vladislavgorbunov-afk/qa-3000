#!/usr/bin/env python3
"""Minimal TestRail API client for the qa-3000 skill.

Usage:
    testrail.py projects
    testrail.py suites <project_id>
    testrail.py sections <project_id> <suite_id>
    testrail.py add-section <project_id> <suite_id> <name> [parent_id]
    testrail.py add-cases <section_id> <cases.json | ->

Credentials: TESTRAIL_URL, TESTRAIL_USER and TESTRAIL_API_KEY, or a JSON file
{"base_url", "email", "api_key"} named by TESTRAIL_CONFIG.

add-cases takes a JSON array of add_case bodies and prints one
"C<id> <url>  <title>" line per created case. It stops at the first failure;
the cases created before it are already printed, so you can resume.
"""

import base64
import json
import os
import sys
import urllib.error
import urllib.request


def config():
    path = os.environ.get("TESTRAIL_CONFIG")
    if path:
        with open(path) as f:
            cfg = json.load(f)
    else:
        cfg = {
            "base_url": os.environ.get("TESTRAIL_URL"),
            "email": os.environ.get("TESTRAIL_USER"),
            "api_key": os.environ.get("TESTRAIL_API_KEY"),
        }
    missing = [k for k in ("base_url", "email", "api_key") if not cfg.get(k)]
    if missing:
        sys.exit("TestRail credentials missing: " + ", ".join(missing) + " (see --help)")
    cfg["base_url"] = cfg["base_url"].rstrip("/")
    return cfg


def call(cfg, path, body=None):
    url = f"{cfg['base_url']}/index.php?/api/v2/{path}"
    auth = base64.b64encode(f"{cfg['email']}:{cfg['api_key']}".encode()).decode()
    req = urllib.request.Request(
        url,
        data=None if body is None else json.dumps(body).encode(),
        method="GET" if body is None else "POST",
        headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def get_all(cfg, path, key):
    """Follow TestRail's paginated responses ({key: [...], _links: {next}})."""
    out, page = [], call(cfg, path)
    while isinstance(page, dict):
        out += page.get(key, [])
        nxt = (page.get("_links") or {}).get("next")
        if not nxt:
            return out
        page = call(cfg, nxt.split("/api/v2/", 1)[1])
    return out + page  # older instances return a bare list


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    cmd, args = argv[0], argv[1:]
    cfg = config()
    if cmd == "projects" and not args:
        for p in get_all(cfg, "get_projects", "projects"):
            print(f"{p['id']}\t{p['name']}\tsuite_mode={p.get('suite_mode')}")
    elif cmd == "suites" and len(args) == 1:
        for s in call(cfg, f"get_suites/{args[0]}"):
            print(f"{s['id']}\t{s['name']}")
    elif cmd == "sections" and len(args) == 2:
        for s in get_all(cfg, f"get_sections/{args[0]}&suite_id={args[1]}", "sections"):
            print(f"{s['id']}\tparent={s.get('parent_id') or '-'}\tdepth={s.get('depth')}\t{s['name']}")
    elif cmd == "add-section" and len(args) in (3, 4):
        body = {"suite_id": int(args[1]), "name": args[2]}
        if len(args) == 4:
            body["parent_id"] = int(args[3])
        s = call(cfg, f"add_section/{args[0]}", body)
        print(f"{s['id']}\t{s['name']}")
    elif cmd == "add-cases" and len(args) == 2:
        cases = json.load(sys.stdin) if args[1] == "-" else json.load(open(args[1]))
        if not isinstance(cases, list):
            sys.exit("Input must be a JSON array of case objects.")
        for i, case in enumerate(cases, 1):
            try:
                c = call(cfg, f"add_case/{args[0]}", case)
            except urllib.error.HTTPError as e:
                sys.exit(f"Failed on case #{i} '{case.get('title', '?')}': HTTP {e.code} {e.read().decode()}")
            print(f"C{c['id']}  {cfg['base_url']}/index.php?/cases/view/{c['id']}  {case.get('title', '')}")
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
