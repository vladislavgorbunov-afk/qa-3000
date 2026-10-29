#!/usr/bin/env python3
"""Pick the element to tap by its visible label — shared by tap_text_android.sh and tap_text_ios.sh.

A node is (label, x, y, area): the label with a merged node's lines joined by " | ", its centre
and its area. The query matches, case-insensitively:
  1. a whole label — several such nodes: the smallest, the innermost one;
  2. else the one single-line label that contains it.
Not tapped: several single-line labels containing it (ambiguous), or a hit only inside a merged
label (`Topic | Finance | Change`) — that node's centre is another element.

    tap_match.py android "<label>|--list" < uiautomator.xml   prints "TAP x,y<TAB>label" or why not
"""
import html, re, sys


def listing(nodes):
    return [f"{x:.0f},{y:.0f}\t{l}" for l, x, y, _ in nodes]


def pick(nodes, q):
    """(node, None) to tap, or (None, why not)."""
    ql = q.lower()
    exact = [n for n in nodes if n[0].lower() == ql]
    if exact:
        return min(exact, key=lambda n: n[3]), None
    inside = [n for n in nodes if ql in n[0].lower()]
    single = [n for n in inside if " | " not in n[0]]
    if len(single) == 1:
        return single[0], None
    if single:
        return None, "AMBIGUOUS: " + q + " — pass one whole label:\n" + "\n".join(listing(single))
    if inside:
        return None, ("ONLY INSIDE A MERGED LABEL: " + q + " — its centre is another element; pass the whole label "
                      "to tap that node, or tap the element by its coordinates:\n" + "\n".join(listing(inside)))
    return None, "NOT FOUND: " + q + "\nvisible: " + " ; ".join(n[0] for n in nodes)


def run(nodes, q):
    """--list or a pick, printed; the exit code for the calling script (0 tap, 2 no tap)."""
    if q in ("", "--list"):
        print("\n".join(listing(nodes)))
        return 0
    n, why = pick(nodes, q)
    if not n:
        print(why)
        return 2
    print(f"TAP {n[1]:.0f},{n[2]:.0f}\t{n[0]}")
    return 0


def android_nodes(xml):
    nodes = []
    for m in re.finditer(r'<node [^>]*>', xml):
        n = m.group(0)
        lab = html.unescape((re.search(r'content-desc="([^"]*)"', n) or [None, ''])[1] or (re.search(r' text="([^"]*)"', n) or [None, ''])[1])
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        if lab.strip() and b:
            x1, y1, x2, y2 = map(int, b.groups())
            nodes.append((lab.strip().replace('\n', ' | '), (x1 + x2) // 2, (y1 + y2) // 2, (x2 - x1) * (y2 - y1)))
    return nodes


if __name__ == "__main__" and len(sys.argv) == 3 and sys.argv[1] == "android":
    sys.exit(run(android_nodes(sys.stdin.read()), sys.argv[2]))
