"""Writes the options-window translations into locales/*.lua (run from the addon folder).

    python gen_locales.py <keys.txt> [--check]

Each locale file gets one block, between the BEGIN/END markers below, put before its
final `return L`; running again replaces the block.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from translations import WINDOW, CONSTANTS, COLUMN  # noqa: E402

BEGIN = "-- BEGIN options window strings (generated)"
END = "-- END options window strings"

KEY_RE = re.compile(r'L\["((?:[^"\\]|\\.)+)"\]')
SPEC_RE = re.compile(r'%[sd]')


def lua(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def check(keys_path):
    keys = set(KEY_RE.findall(open(keys_path, encoding="utf-8").read()))
    ok = True
    for k in sorted(keys - set(WINDOW)):
        print("missing translation:", k)
        ok = False
    for k in sorted(set(WINDOW) - keys):
        print("translated but unused:", k)
    for k, row in WINDOW.items():
        assert len(row) == 8, k
        for t in row:
            if sorted(SPEC_RE.findall(t)) != sorted(SPEC_RE.findall(k)):
                print("format mismatch:", k, "->", t)
                ok = False
    for k, (en, row) in CONSTANTS.items():
        assert len(row) == 8, k
        for t in row:
            if SPEC_RE.findall(t) != SPEC_RE.findall(en):
                print("format mismatch:", k, "->", t)
                ok = False
    return ok


def block(locale):
    lines = [BEGIN]
    if locale == "enUS":
        lines.append("-- The window's own strings are keyed by their English text and need no entry here.")
        for k in sorted(CONSTANTS):
            lines.append("L.%s = %s" % (k, lua(CONSTANTS[k][0])))
    else:
        col = COLUMN[locale]
        for k in sorted(CONSTANTS):
            lines.append("L.%s = %s" % (k, lua(CONSTANTS[k][1][col])))
        lines.append("-- The options window, keyed by its English text")
        for k in sorted(WINDOW):
            t = WINDOW[k][col]
            if t != k:
                lines.append("L[%s] = %s" % (lua(k), lua(t)))
    lines.append(END)
    return "\n".join(lines) + "\n"


def write(locale):
    path = os.path.join("locales", locale + ".lua")
    raw = open(path, "rb").read()
    nl = "\r\n" if b"\r\n" in raw else "\n"
    text = raw.decode("utf-8").replace("\r\n", "\n")
    text = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n\n?", "", text, flags=re.S)
    at = text.rstrip().rfind("return L")
    assert at >= 0, path
    text = text[:at].rstrip("\n") + "\n\n" + block(locale) + "\n" + text[at:]
    open(path, "wb").write(text.replace("\n", nl).encode("utf-8"))


if __name__ == "__main__":
    if not check(sys.argv[1]):
        sys.exit(1)
    if "--check" in sys.argv:
        sys.exit(0)
    for locale in ["enUS", "deDE", "esES", "esMX", "frFR", "ptBR", "ruRU", "koKR", "zhCN", "zhTW"]:
        write(locale)
    print("wrote 10 locale files")
