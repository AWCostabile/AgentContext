"""sibling-instruction.py - the PostToolUse hook's body (see sibling-instruction.sh).

argv[1] is the instance root; the hook JSON is on stdin. When the tool's path falls under a
workspace sibling this session has not touched yet, prints the sibling's identity line and its
instruction file as additional context and records the sibling as touched. Any failure prints
nothing.
"""
import glob
import json
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from relpath import norm  # noqa: E402  (the same path spellings the other hooks accept)


def siblings(root):
    """The workspace file's folders other than the tree and its private tree, as (name, path)."""
    out = []
    for ws in glob.glob(os.path.join(root, "*.code-workspace")):
        try:
            text = open(ws, encoding="utf-8").read()
        except OSError:
            continue
        for p in re.findall(r'"path"\s*:\s*"([^"]*)"', text):
            if p in (".", "./", "./private", "private"):
                continue
            ap = p if re.match(r"^([A-Za-z]:|/)", p) else os.path.join(root, p)
            ap = norm(os.path.abspath(ap))
            if os.path.isdir(ap):
                out.append((os.path.basename(ap), ap))
    return out


def touched(data, sibs):
    """The siblings a tool call touched: by the path fields of the file tools, by the text of a
    Bash command."""
    ti = data.get("tool_input") or {}
    hits = []
    if data.get("tool_name") == "Bash":
        cmd = (ti.get("command") or "").lower()
        for name, ap in sibs:
            if ap.lower() in cmd.replace("\\", "/") or ("../" + name.lower() + "/") in cmd.replace("\\", "/") or ("../" + name.lower() + " ") in cmd.replace("\\", "/"):
                hits.append((name, ap))
        return hits
    paths = [ti.get(k) for k in ("file_path", "path", "notebook_path") if isinstance(ti.get(k), str) and ti.get(k)]
    cwd = data.get("cwd") or os.getcwd()
    for p in paths:
        if not (p.startswith(("/", "\\")) or re.match(r"^[A-Za-z]:", p)):
            p = os.path.join(cwd, p)
        p = norm(p).lower()
        for name, ap in sibs:
            if p == ap.lower() or p.startswith(ap.lower().rstrip("/") + "/"):
                hits.append((name, ap))
    return hits


def instruction(ap):
    """The sibling's instruction: CLAUDE.md, unless it is the one-line import of AGENTS.md."""
    for fn in ("CLAUDE.md", "AGENTS.md"):
        f = os.path.join(ap, fn)
        if os.path.isfile(f):
            try:
                body = open(f, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            if fn == "CLAUDE.md" and body.strip() == "@AGENTS.md" and os.path.isfile(os.path.join(ap, "AGENTS.md")):
                continue
            return fn, body.rstrip()
    return "", ""


def identity(ap):
    try:
        with open(os.path.join(ap, ".agents", ".id.meta"), encoding="utf-8") as f:
            kv = dict(l.rstrip("\r\n").split("=", 1) for l in f if "=" in l)
        return kv.get("id", ""), kv.get("name", "")
    except OSError:
        return "", ""


def main():
    root = sys.argv[1]
    data = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
    sid = data.get("session_id") or ""
    if not isinstance(sid, str) or not sid:
        return
    sibs = siblings(root)
    if not sibs:
        return
    hits = touched(data, sibs)
    if not hits:
        return
    tmp = os.environ.get("TMPDIR") or os.environ.get("TEMP") or "/tmp"
    marker = os.path.join(tmp, "knowledge-tree-siblings." + re.sub(r"[^A-Za-z0-9_.-]", "_", sid))
    seen = set()
    try:
        seen = set(open(marker, encoding="utf-8").read().split("\n"))
    except OSError:
        pass
    parts = []
    for name, ap in hits:
        if ap.lower() in seen:
            continue
        seen.add(ap.lower())
        pid, pname = identity(ap)
        fn, body = instruction(ap)
        head = "First touch of the workspace project %s (%s)." % (name, ap)
        if pid:
            head += " Identity (.agents/.id.meta): id=%s name=%s." % (pid, pname)
        if fn:
            head += " Its instruction file, %s, applies while you work there:" % fn
            parts.append(head + "\n\n" + body)
        else:
            parts.append(head + " It carries no instruction file.")
    try:
        with open(marker, "w", encoding="utf-8") as f:
            f.write("\n".join(sorted(s for s in seen if s)))
        now = time.time()
        for old in glob.glob(os.path.join(tmp, "knowledge-tree-siblings.*")):
            if now - os.path.getmtime(old) > 2 * 86400:
                os.remove(old)
    except OSError:
        pass
    if parts:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "\n\n".join(parts)}}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
