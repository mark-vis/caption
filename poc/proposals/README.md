# Supporting files for `poc/PROPOSALS.md`

DRAFT, 2026-10-04. Everything here is written against latex2e `develop` at
829e56a15 (https://github.com/latex3/latex2e) and caption v3.6p (this repository,
`source/`, branch `fixes-combined`).

## Contents

| Path | What |
|---|---|
| `patches/series/0001-…0004-*.patch` | the four kernel/latex-lab patches in the order (a), (d), (b), (c), made with `git format-patch`; they apply in sequence to 829e56a15 |
| `patches/combined.diff` | the same four as one diff |
| `patches/standalone/a-float-hooks.patch` | (a) alone (identical to series 0001) |
| `patches/standalone/b-caption-interface.patch` | (b) alone: declares `float/<type>/sub` in the `float/new` key and does not use (d)'s helper |
| `patches/standalone/d-tagging-float-types.patch` | (d) alone: series 0002 plus the version line of latex-lab-float |
| `patches/caption-floathooks.diff` | caption side of (a), against the generated caption.sty v3.6p |
| `patches/newfloat-v1.2a.diff` | newfloat side of (d), against newfloat.dtx v1.2 (TeX Live 2026); newfloat lives in its own repository, https://gitlab.com/axelsommerfeldt/newfloat |
| `tests/` | the new l3build tests (copies of the files in the patches): base `tlb-float-hooks-001`, `tlb-float-hooks-002-rollback` (a), `caption-interface-001` (b); latex-lab `testfiles-float/float-017-declare` (d), `float-020-caption-interface`, `float-028-caption-star-wide` (b), `float-021-caption-label`, `float-022-caption-separator`, `float-025-makecaption-label`, `float-026-makecaption-voids`, `float-027-caption-in-box` (c) |
| `mwe/` | the test documents and sketches (see below) |
| `scripts/` | scripts that reproduce the checks |

There is no stand-alone (c): it needs (b). The patches also contain the updated `.tlg`
files of existing tests (rollback tests, `config-lthooks`, `float-010-outside`) and
`changes.txt` entries.

### Documents in `mwe/`

| Files | Proposal | Purpose |
|---|---|---|
| `a1-cmdhook-babel.tex`, `a1b-cmdhook-nobabel.tex` | (a) | the generic `cmd/@xfloat/after` hook fails with babel-french (TL 2026) |
| `a2-caption-user.tex`, `a3-caption-user-tagging.tex` | (a) | caption with type options, two columns, babel-french, hyperref; without and with tagging |
| `a4-nested-H.tex` | (a) | float.sty `[H]` float in a minipage in a figure: `float/end` only once |
| `a5-body.tex` + `a5-plain/-setspace/-float/-xdbl/-bypass/-rollback.tex` | (a) | caption's guard and fallback wrapper (needs the patched caption.sty) |
| `a6-rollback-tagging.tex`, `a6x.tex` | (a) | rollback under tagging |
| `b-kernel.tex`, `b-tagging.tex` | (b) | the problem on TL 2026 |
| `captionclient.sty`, `client-doc*.tex` | (b) | sketch of caption as a client of the interface, and its test documents |
| `caption-excerpt.tex`, `caption-excerpt-doc.tex` | (b) | the caption.sty excerpt of (b)5, with stubs |
| `cls-star.tex` | (b) | `\caption*` with other classes: `pdflatex "\def\cls{memoir}\input cls-star"` |
| `release-back.tex`, `release-fwd.tex` | (b) | `latexrelease` rollback and roll-forward |
| `c-kernel.tex`, `c-caption.tex`, `c-inpar.tex` | (c) | the problem on TL 2026 (`c-inpar.tex` works with the patch) |
| `caption3-labelplug.tex`, `caption-sty-remove.tex` | (c) | proposed caption3/caption.sty code of (c)5 |
| `c-caption3-plug.tex`, `c-caption-remove.tex`, `remove-notag.tex`, `voids-notag.tex` | (c) | tests of that code |
| `d1-manual-float*.tex`, `d2`…`d12` | (d) | float types defined by hand, by newfloat, caption, tocbasic, memoir, float.sty, floatrow(bytocbasic) |

## How to rerun the checks

Requirements: TeX Live 2026 with l3build, pdfTeX and LuaTeX; git, perl; poppler's
`pdftotext`/`pdfinfo`. About 3 GB of scratch space and, with 7 parallel jobs, about
30 minutes.

```sh
sh poc/proposals/scripts/run-checks.sh /path/to/scratch [/path/to/latex2e-clone]
```

`run-checks.sh` clones latex2e (or copies the given clone, which it does not change),
checks out 829e56a15, and makes one tree copy per group of l3build jobs (l3build runs in
the same tree share its `build/` directory and must not overlap). Variants: `stock`
(unpatched), `all` (the series), `a`, `b`, `d` (stand-alone patches). Then it

1. runs `scripts/check-job.sh` for each group, at most `JOBS` (default 7) in parallel:
   the base tests listed in `check-job.sh` (pdfTeX and LuaTeX), base `config-lthooks`,
   latex-lab `config-float`, `config-table-pdftex`, `config-table-luatex` and
   `config-block firstaid-listings`; every run is under `alarm`;
2. writes `summary.txt`: each failing test with its distinct differing lines, and
   tests that do not exist in a variant;
3. builds caption v3.6p from `source/`, the caption.sty with the float hooks, and
   newfloat v1.2a (`scripts/build-inputs.sh`);
4. compiles the documents in `mwe/` against the formats of the `stock` and `all` trees
   (`scripts/docs.sh`) and writes `docs-stock.txt` and `docs-all.txt` (errors, tagpdf
   warnings, the lists of figures and structure excerpts), and compares the a2/a3
   output of develop + stock caption with that of the combined patch + caption with
   hooks.

Expected result: see "Verification of the combined patch" in `poc/PROPOSALS.md`. With a
show-pdf-tags that writes `<PDF>` instead of `<PDF version="2.0">`, the tests
`firstaid-float-H-2`, `firstaid-listings` and (LuaTeX) `table-015-hhline` (all also on
unpatched develop) and the new float-017/020/021/022 differ in that one line.

To apply the patches by hand:

```sh
git clone https://github.com/latex3/latex2e.git && cd latex2e
git checkout -b proposals 829e56a15
git am /path/to/poc/proposals/patches/series/*.patch   # or: git apply .../combined.diff
cd base && l3build check -e pdftex,luatex tlb-float-hooks-001 caption-interface-001
cd ../required/latex-lab && l3build check -c config-float
```
