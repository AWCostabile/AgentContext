"""relpath.py - hook helper: print the tree-relative path of tool_input.file_path.

Reads the hook JSON on stdin; argv[1] is the tree root. Prints the path relative to
the root with forward slashes, or nothing when the path is missing, relative to
nowhere, or outside the tree. Accepts every spelling a harness may produce on Windows
under a POSIX shell (`C:\\dir\\f`, `c:/dir/f`, `/c/dir/f`, `/cygdrive/c/...`) as well as
plain POSIX paths, and paths relative to the hook's `cwd`.
"""
import json
import os
import re
import sys


def norm(p):
    p = p.replace("\\", "/")
    m = re.match(r"^/(?:cygdrive/)?([A-Za-z])(/.*)?$", p)
    if m:
        p = m.group(1) + ":" + (m.group(2) or "/")
    if re.match(r"^[A-Za-z]:/", p):
        p = p[0].lower() + p[1:]
    return os.path.normpath(p).replace("\\", "/")


def main():
    if len(sys.argv) < 2:
        return
    root = norm(sys.argv[1])
    try:
        data = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
    except Exception:
        return
    ti = data.get("tool_input") or {}
    path = ti.get("file_path") or ti.get("path") or ""
    if not isinstance(path, str) or not path:
        return
    if not (path.startswith(("/", "\\")) or re.match(r"^[A-Za-z]:", path)):
        cwd = data.get("cwd") or os.getcwd()
        path = norm(cwd) + "/" + path
    path = norm(path)
    if path.lower() == root.lower():
        return
    prefix = root.lower().rstrip("/") + "/"
    if not path.lower().startswith(prefix):
        return
    print(path[len(prefix):])


if __name__ == "__main__":
    main()
