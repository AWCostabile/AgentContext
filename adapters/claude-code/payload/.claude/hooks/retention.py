"""retention.py - the SessionStart hook's body (see retention.sh).

argv[1] is the instance root; the hook JSON is on stdin; RETENTION_ROWS carries the rows of the
context-retention module's `check --porcelain` over the instance and its workspace folders, run
by the shell wrapper. Repairs this harness's project directory for every moved project it can
derive and prints the hook's JSON. Any failure prints nothing.
"""
import json
import os
import re
import shutil
import sys

META = "modules/context-retention/meta.sh"


def encode(path):
    """The harness's project-directory name for a path: every character outside [A-Za-z0-9]
    becomes a hyphen. Proven against the session's own transcript_path before it is trusted."""
    return re.sub(r"[^A-Za-z0-9]", "-", path)


def find_dir(parent, name):
    """The entry of parent named `name`, matched without regard to case (the harness keeps the
    drive letter's case as the process saw it); None when absent."""
    try:
        for e in os.listdir(parent):
            if e.lower() == name.lower():
                return os.path.join(parent, e)
    except OSError:
        pass
    return None


def merge(old, new):
    """Move old's files into new without overwriting; one level of subdirectory (memory/) is
    merged file by file. Returns (transcripts, memory files, conflicts)."""
    t = m = 0
    conflicts = []
    for entry in sorted(os.listdir(old)):
        src = os.path.join(old, entry)
        dst = os.path.join(new, entry)
        if not os.path.lexists(dst):
            shutil.move(src, dst)
            if entry.endswith(".jsonl"):
                t += 1
            elif os.path.isdir(dst):
                m += sum(len(f) for _, _, f in os.walk(dst))
            continue
        if os.path.isdir(src) and os.path.isdir(dst) and not os.path.islink(src):
            for sub in sorted(os.listdir(src)):
                s2, d2 = os.path.join(src, sub), os.path.join(dst, sub)
                if os.path.lexists(d2):
                    conflicts.append(entry + "/" + sub)
                else:
                    shutil.move(s2, d2)
                    m += 1
            try:
                os.rmdir(src)
            except OSError:
                pass
        else:
            conflicts.append(entry)
    try:
        os.rmdir(old)
    except OSError:
        pass
    return t, m, conflicts


def identity(path):
    try:
        with open(os.path.join(path, ".agents", ".id.meta"), encoding="utf-8") as f:
            kv = dict(l.rstrip("\r\n").split("=", 1) for l in f if "=" in l)
        return kv.get("id", ""), kv.get("name", "")
    except OSError:
        return "", ""


def main():
    root = sys.argv[1]
    try:
        data = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
    except Exception:
        data = {}
    transcript = data.get("transcript_path") or ""
    lines = []
    pid, pname = identity(root)
    if pid:
        lines.append("Project identity (%s/.agents/.id.meta): id=%s name=%s" % (os.path.basename(root), pid, pname))

    out = os.environ.get("RETENTION_ROWS") or ""
    rows = [l.split("\t") for l in out.splitlines() if l.strip()]

    projects_root = os.path.dirname(transcript) if transcript else ""
    own_dir = os.path.basename(projects_root) if projects_root else ""
    cwd = data.get("cwd") or ""
    rule_ok = bool(own_dir and cwd and encode(cwd).lower() == own_dir.lower())
    projects_root = os.path.dirname(projects_root) if projects_root else ""

    for row in rows:
        if len(row) < 3:
            continue
        kind, rid, path = row[0], row[1], row[2]
        old = row[3] if len(row) > 3 else ""
        name = os.path.basename(path.rstrip("/"))
        if kind == "copied":
            lines.append("Copied, not moved: %s (%s) carries the same id as %s; remove its .agents/.id.meta and run `bash %s init %s`" % (name, rid, old, META, path))
            continue
        if kind == "bad":
            lines.append("Malformed: %s/.agents/.id.meta is not id=, name=, created= and nothing else" % path)
            continue
        if kind != "moved":
            continue
        if not rule_ok or not projects_root:
            lines.append("Moved: %s (%s) was at %s, now at %s; this harness filed its sessions and memory under %s — move them by hand into the directory named for the new path" % (name, rid, old, path, encode(old)))
            continue
        old_dir = find_dir(projects_root, encode(old))
        if not old_dir or os.path.islink(old_dir):
            lines.append("Moved: %s (%s) was at %s, now at %s; nothing of it was filed under the old path" % (name, rid, old, path))
            continue
        new_dir = find_dir(projects_root, encode(path)) or os.path.join(projects_root, encode(path))
        try:
            if not os.path.lexists(new_dir):
                os.rename(old_dir, new_dir)
                t = len([f for f in os.listdir(new_dir) if f.endswith(".jsonl")])
                m = sum(len(f) for _, _, f in os.walk(os.path.join(new_dir, "memory")))
                conflicts = []
            else:
                t, m, conflicts = merge(old_dir, new_dir)
        except Exception as e:
            lines.append("Moved: %s (%s) was at %s, now at %s; the repair of %s failed (%s) — move its files by hand into %s" % (name, rid, old, path, old_dir, e.__class__.__name__, new_dir))
            continue
        msg = "Moved: %s (%s) was at %s, now at %s — re-attached %d transcript(s) and %d memory file(s) under %s; the resume picker lists the old sessions" % (name, rid, old, path, t, m, new_dir)
        if conflicts:
            msg += "; left in %s because the new directory already had them: %s" % (old_dir, ", ".join(conflicts[:5]))
        lines.append(msg)

    if lines:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "\n".join(lines)}}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
