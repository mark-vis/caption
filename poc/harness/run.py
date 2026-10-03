#!/usr/bin/env python3
"""Compare caption.sty (reference) with caption4 (new) on the PoC test documents.

For every test document, engine and mode (notag / tag) the document is compiled
three times per variant in its own directory, and the following are collected:
errors, warnings, every word with its position (pdftotext -bbox), the list-of
files (.lof/.lot/.lol) and the \\newlabel data, and in tag mode the structure
tree (pdfinfo -struct-text).

Comparisons:
  notag: new        vs ref        (everything must match)
  tag:   new (tag)  vs ref (notag) for words, lists and labels: with tagging on,
         caption4 should typeset exactly what caption.sty typesets without tagging
         (caption.sty itself loses its settings under tagging);
         plus a structure summary of new (tag) next to ref (tag).

Usage: run.py --ref DIR --new DIR [--tests GLOB] [--engines pdflatex,lualatex]
              [--modes notag,tag] [--jobs N] [--out DIR] [--keep]
  --ref/--new: directories with the .sty/.sto files of each variant.
"""
import argparse, concurrent.futures as cf, glob, json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TESTS = os.path.join(os.path.dirname(HERE), "tests")
SUBST = {"ref": {"%CAPTION%": "caption", "%SUBCAPTION%": "subcaption"},
         "new": {"%CAPTION%": "caption4", "%SUBCAPTION%": "subcaption4"}}


def run(cmd, cwd, timeout=120):
    try:
        return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                              errors="replace", timeout=timeout)
    except subprocess.TimeoutExpired:
        return None


def compile_one(job):
    test, engine, mode, variant, styd, out = job
    name = os.path.splitext(os.path.basename(test))[0]
    wd = os.path.join(out, f"{name}.{engine}.{mode}.{variant}")
    shutil.rmtree(wd, ignore_errors=True)
    os.makedirs(wd)
    src = open(test).read()
    for k, v in SUBST[variant].items():
        src = src.replace(k, v)
    if mode == "tag":
        src = "\\DocumentMetadata{tagging=on}\n" + src
    open(os.path.join(wd, "doc.tex"), "w").write(src)
    for f in glob.glob(os.path.join(styd, "*.sty")) + glob.glob(os.path.join(styd, "*.sto")):
        shutil.copy(f, wd)
    timeout = False
    for _ in range(3):
        r = run([engine, "-interaction=nonstopmode", "-halt-on-error", "doc.tex"], wd)
        if r is None:
            timeout = True
            break
    res = {"timeout": timeout}
    log = open(os.path.join(wd, "doc.log"), errors="replace").read() if os.path.exists(os.path.join(wd, "doc.log")) else ""
    res["errors"] = [l for l in log.splitlines() if l.startswith("!")]
    # warnings: first line of each "... Warning: ..." message, line numbers removed
    warns = re.findall(r"^((?:Package|Class|LaTeX|pdfTeX|Module) .*?[Ww]arning.*)$", log, re.M)
    res["warnings"] = sorted(set(re.sub(r"on input line \d+", "", w).strip() for w in warns))
    pdf = os.path.join(wd, "doc.pdf")
    res["pdf"] = os.path.exists(pdf)
    words = []
    if res["pdf"]:
        bb = run(["pdftotext", "-bbox", "doc.pdf", "-"], wd)
        page = 0
        for line in (bb.stdout if bb else "").splitlines():
            if "<page " in line:
                page += 1
            m = re.search(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*)</word>', line)
            if m:
                words.append([page, m.group(5), round(float(m.group(1)), 2), round(float(m.group(2)), 2)])
    res["words"] = words
    lists = {}
    for ext in ("lof", "lot", "lol"):
        p = os.path.join(wd, "doc." + ext)
        if os.path.exists(p):
            lists[ext] = [l for l in open(p, errors="replace").read().splitlines()
                          if "contentsline" in l]
    res["lists"] = lists
    aux = os.path.join(wd, "doc.aux")
    res["labels"] = sorted(l for l in open(aux, errors="replace").read().splitlines()
                           if l.startswith("\\newlabel")) if os.path.exists(aux) else []
    if mode == "tag" and res["pdf"]:
        st = run(["pdfinfo", "-struct-text", "doc.pdf"], wd)
        res["struct"] = st.stdout if st else ""
    return (name, engine, mode, variant), res


def first_diff(a, b, n=3):
    out = []
    for i in range(max(len(a), len(b))):
        x = a[i] if i < len(a) else None
        y = b[i] if i < len(b) else None
        if x != y:
            out.append(f"    [{i}] ref={x}\n         new={y}")
            if len(out) >= n:
                break
    return out


IGNORE_WARN = ("Neither unicode-math nor lua-unicode-math",)


def norm_lists(lists):
    # tagging adds the anchor as 4th argument of \contentsline
    return {k: [re.sub(r"\{[^{}]*\}%$", "{}%", l) for l in v] for k, v in lists.items()}


def norm_labels(labels):
    # tagging fills the name field (3rd) of \newlabel; keep label, value, page, anchor
    out = []
    for l in labels:
        m = re.match(r"(\\newlabel\{[^}]*\})\{\{(.*?)\}\{(.*?)\}\{.*?\}\{(.*?)\}", l)
        out.append(m.groups() if m else l)
    return out


def words_close(a, b, tol):
    if len(a) != len(b):
        return False
    return all(x[0] == y[0] and x[1] == y[1] and abs(x[2] - y[2]) <= tol and abs(x[3] - y[3]) <= tol
               for x, y in zip(a, b))


def struct_summary(s):
    tags = re.findall(r"^\s*(\w+)", s or "", re.M)
    keep = ["Caption", "Lbl", "Figure", "Aside", "Part", "Div", "Table", "Reference", "Link"]
    return {t: tags.count(t) for t in keep if tags.count(t)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref", required=True)
    ap.add_argument("--new", required=True)
    ap.add_argument("--tests", default="t*.tex")
    ap.add_argument("--engines", default="pdflatex,lualatex")
    ap.add_argument("--modes", default="notag,tag")
    ap.add_argument("--jobs", type=int, default=13)
    ap.add_argument("--out", default="/tmp/caption4-harness")
    ap.add_argument("--json", default=None)
    ap.add_argument("--selftest", action="store_true", help="use the reference package names for new, too")
    a = ap.parse_args()
    if a.selftest:
        SUBST["new"] = dict(SUBST["ref"])
    tests = sorted(glob.glob(os.path.join(TESTS, a.tests)))
    engines, modes = a.engines.split(","), a.modes.split(",")
    jobs = []
    for t in tests:
        for e in engines:
            for m in modes:
                for v, d in (("ref", a.ref), ("new", a.new)):
                    jobs.append((t, e, m, v, os.path.abspath(d), a.out))
            if "tag" in modes and "notag" not in modes:  # tag compares against ref notag
                jobs.append((t, e, "notag", "ref", os.path.abspath(a.ref), a.out))
    R = {}
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        for k, v in ex.map(compile_one, jobs):
            R[k] = v
    if a.json:
        json.dump({"|".join(k): v for k, v in R.items()}, open(a.json, "w"), indent=1)
    bad = 0
    for t in tests:
        name = os.path.splitext(os.path.basename(t))[0]
        for e in engines:
            for m in modes:
                new = R[(name, e, m, "new")]
                ref = R[(name, e, "notag", "ref")]
                reft = R.get((name, e, m, "ref"))
                probs = []
                if new["timeout"]:
                    probs.append("  new: TIMEOUT")
                if new["errors"]:
                    probs.append(f"  new: {len(new['errors'])} errors, first: {new['errors'][0]}")
                if ref["errors"]:
                    probs.append(f"  ref: {len(ref['errors'])} errors, first: {ref['errors'][0]}")
                tagcmp = (m == "tag")
                cmp = {"words": (ref["words"], new["words"]),
                       "lists": (norm_lists(ref["lists"]) if tagcmp else ref["lists"],
                                 norm_lists(new["lists"]) if tagcmp else new["lists"]),
                       "labels": (norm_labels(ref["labels"]) if tagcmp else ref["labels"],
                                  norm_labels(new["labels"]) if tagcmp else new["labels"])}
                for key in ("words", "lists", "labels"):
                    r_, n_ = cmp[key]
                    same = words_close(r_, n_, 1.5) if (key == "words" and tagcmp) else r_ == n_
                    if not same:
                        if key == "words":
                            probs.append("  words differ:\n" + "\n".join(first_diff(r_, n_)))
                        elif key == "lists":
                            for ext in sorted(set(ref[key]) | set(new[key])):
                                d = first_diff(r_.get(ext, []), n_.get(ext, []))
                                if d:
                                    probs.append(f"  {ext} differs:\n" + "\n".join(d))
                        else:
                            probs.append("  labels differ:\n" + "\n".join(first_diff(r_, n_)))
                extra = sorted(w for w in set(new["warnings"]) - set(ref["warnings"])
                               if not any(i in w for i in IGNORE_WARN))
                if extra:
                    probs.append("  new warnings: " + "; ".join(extra[:4]))
                if m == "tag":
                    probs.append(f"  struct new={struct_summary(new.get('struct'))} ref(tag)={struct_summary(reft.get('struct') if reft else '')}")
                hard = [p for p in probs if not p.startswith("  struct")]
                status = "OK  " if not hard else "DIFF"
                bad += bool(hard)
                print(f"{status} {name:28s} {e:9s} {m}")
                for p in probs:
                    if hard or m == "tag":
                        print(p)
    print(f"\n{bad} of {len(tests) * len(engines) * len(modes)} combinations differ")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
