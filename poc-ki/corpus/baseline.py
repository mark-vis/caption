#!/usr/bin/env python3
# baseline.py OUTDIR... : one row per job, cells "errors/captionW/tagpdfW/hyperrefW/otherW" per
# kernel-dir and engine (p = pdflatex, l = lualatex); rows that are clean everywhere are skipped
# unless -a is given.
import sys, csv, os
args = [a for a in sys.argv[1:] if a != "-a"]; all_rows = "-a" in sys.argv
data = {}
for d in args:
    for r in csv.DictReader(open(os.path.join(d, "summary.tsv")), delimiter="\t"):
        cell = "/".join(r[k] for k in ("errors", "captionW", "tagpdfW", "hyperrefW", "otherW"))
        if r["runs"] != "0,0,0": cell += "!rc"
        data.setdefault(r["job"], {})[(os.path.basename(d.rstrip("/")), r["engine"][0])] = cell
cols = [(os.path.basename(d.rstrip("/")), e) for d in args for e in "pl"]
print("job".ljust(36), " ".join(f"{c[0][4:]}:{c[1]}".ljust(12) for c in cols))
for job in sorted(data):
    cells = [data[job].get(c, "-") for c in cols]
    if all_rows or any(c != "0/0/0/0/0" for c in cells):
        print(job.ljust(36), " ".join(c.ljust(12) for c in cells))
