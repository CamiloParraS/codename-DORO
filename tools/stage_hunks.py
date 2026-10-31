"""Stage only the hunks of a file whose changed lines match a regex, when the tree mixes several pieces of work.

    python tools/stage_hunks.py <file> <regex>          # stage the matching hunks
    python tools/stage_hunks.py <file> <regex> -n       # list hunks, mark the matching ones, stage nothing
    python tools/stage_hunks.py <file> <regex> -v       # stage the hunks that do NOT match

The regex is searched in each hunk's added and removed lines (not its context). Hunks come from
`git diff -U1 <file>` (unstaged against the index), so already-staged hunks are not offered again.
Everything stays bytes end to end: text-mode pipes on Windows rewrite CRLF and mangle UTF-8.
"""
import re
import subprocess
import sys


def git(*args, stdin=None):
    r = subprocess.run(["git", *args], input=stdin, capture_output=True)
    if r.returncode:
        sys.exit("git %s failed:\n%s" % (" ".join(args), r.stderr.decode("utf-8", "replace")))
    return r.stdout


def split(diff):
    """The file header and its hunks, each a list of lines with their line endings."""
    lines = diff.splitlines(keepends=True)
    start = next((i for i, l in enumerate(lines) if l.startswith(b"@@")), len(lines))
    header, hunks = lines[:start], []
    for l in lines[start:]:
        if l.startswith(b"@@"):
            hunks.append([l])
        else:
            hunks[-1].append(l)
    return header, hunks


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # the Windows console's code page can't print ñ
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    flags = {a for a in sys.argv[1:] if a.startswith("-")}
    if len(args) != 2:
        sys.exit(__doc__)
    path, pattern = args
    rx = re.compile(pattern.encode("utf-8"))
    header, hunks = split(git("diff", "-U1", "--no-color", "--", path))
    if not hunks:
        sys.exit("no unstaged hunks in %s" % path)
    picked = []
    for h in hunks:
        changed = b"".join(l[1:] for l in h[1:] if l[:1] in (b"+", b"-"))
        hit = bool(rx.search(changed)) != ("-v" in flags)
        if hit:
            picked.append(h)
        if "-n" in flags:
            print("%s %s" % ("*" if hit else " ", h[0].decode("utf-8", "replace").rstrip()))
    if "-n" in flags or not picked:
        print("%d of %d hunks match" % (len(picked), len(hunks)))
        return
    patch = b"".join(header) + b"".join(b"".join(h) for h in picked)
    git("apply", "--cached", "-", stdin=patch)
    print("staged %d of %d hunks of %s" % (len(picked), len(hunks), path))


if __name__ == "__main__":
    main()
