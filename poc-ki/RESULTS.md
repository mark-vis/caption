# Results: caption on the proposed kernel interfaces (version 1)

2026-10-05, with later changes of 2026-10-06 (section 7). This experiment makes caption,
caption3 and subcaption use version 1 of the kernel interfaces (a)–(d) of `poc/PROPOSALS.md`
(branch `poc-caption4`) when they exist, and checks that nothing changes when they do not.
The gaps it found (section 6) led to version 2 of proposal (b).

> **Label variant.** The measurements in sections 4–6 on the patched kernel were taken with an
> earlier form of proposal (c), which moved latex-lab's `begindocument` code for
> `\@makecaption` to a new hook label `latex-lab/float/makecaption`, and with a client that
> removed the code by that label. That breaks acmart, mitthesis, asmeconf and asmejour, which
> remove the code by the old label `latex-lab-testphase-float`. Proposal (c) now keeps the
> label; section 7 has the re-measurement. The measurements on TeX Live and on unpatched
> develop are not affected.

## 1. What was built

- Branch `poc-kernel-interfaces` starts from caption v3.7 (branch `caption-v3.7`, 122696d).
  The core changes (caption v3.8, caption3 v2.6) and the sub-caption changes (subcaption
  v1.8) were merged with `git merge --no-ff`: bdfc46f, then **ce43fdf**. There were no
  conflicts: the core changes touch only `caption.dtx` and `caption3.dtx`, the sub-caption
  changes only `subcaption.dtx`. The merged files are byte-identical to the separate
  versions, so their CheckSums still hold (caption 3532, caption3 3995, subcaption 620).
- Built from `source/` with `tex caption.ins`. Against v3.7 only `caption.sty`,
  `caption3.sty` and `subcaption.sty` differ; all fallback files and the other packages are
  identical.
- No integration fixes were needed. Every difference below was already found with the core
  or the sub-caption changes alone.
- Kernels: TeX Live 2026; unpatched latex2e develop 829e56a15; and patched develop, i.e.
  829e56a15 with the version-1 series (a), (d), (b), (c) (`kernel-patches/`) and newfloat
  v1.2a.

## 2. Method

- **caption test suite** (302 tests; 310 after section 6), pdfLaTeX and LuaLaTeX, for v3.7
  and for the new code. Each PDF is compared by `pdftotext -bbox` without the Date lines
  (text and positions) and by the md5 of its `.aux`; the lists of failing tests are compared
  as well.
- **Document corpus** (`corpus/`): 17 documents, 78 variant×engine jobs per kernel, 3 runs
  each. Compared: status, errors, warnings, text, `.aux`, lists, `.out` and structure tree.
  `corpus/tgtnorm.py` maps the link target names `<type>.N` and `<type>.struct.N` to one
  token and drops tagpdf mcid records.
- **Structure trees**: `pdfinfo -struct-text` and a summary of the parents of every
  `Caption`.

## 3. Fallback: kernels without the interfaces

Caption test suite:

| kernel | engine | tests | failures v3.7 | failures new | PDFs compared | text/pos differ | aux differ |
|---|---|---|---|---|---|---|---|
| TL 2026 | pdflatex | 302 | 4 | 4 (same list) | 273 | 1* | 0 |
| TL 2026 | lualatex | 302 | 9 | 9 (same list) | 252 | 1* | 0 |
| develop 829e56a15 | pdflatex | 302 | 26 | 26 (same list) | 251 | 1* | 0 |
| develop 829e56a15 | lualatex | 302 | 12 | 12 (same list) | 249 | 1* | 0 |

\* `issues/gitlab/issue_77.pdf`: ltugboat prints the compile time. It is not a real
difference.

The extra failures on develop compared with TL (babel frenchpro/hungarian/magyar,
thesis/fonts, …) come from the l3build formats, for example missing hyphenation patterns.
v3.7 and the new code have them alike.

Corpus: v3.7 against the new code, **0 / 78** jobs differ on TL 2026 and **0 / 78** on
unpatched develop.

## 4. Patched kernel

Corpus totals (summed over the 78 jobs):

| build | errors | jobs with errors | caption W | tagpdf W | hyperref W | other W |
|---|---|---|---|---|---|---|
| v3.7 on unpatched develop | 116 | 4 | 24 | 107 | 0 | 9 |
| v3.7 on patched develop | 39 | 4 | 24 | 49 | 0 | 9 |
| new code on patched develop | 39 | 4 | 24 | 43 | 0 | 9 |

The 6 tagpdf warnings fewer came from a bug (section 6, finding 4); after its fix the new code
gives 49, as v3.7.

- **No new errors.** The errors are identical to v3.7 in every job. The remaining ones are
  known v3.7/kernel cases: float.sty `\newfloat` types unknown to tagging (10/13) and listings
  captions with an empty `\@captype` (8).
- **Text (`pdftotext -layout`) is identical** to v3.7 on unpatched and on patched develop
  in all 78 jobs.
- **Lists and `.aux`:** 28 of 78 jobs differ; after target normalisation 72 of 78 are
  identical. The only list/label difference is the target name: `figure.N` becomes
  `figure.struct.N` (a `\ContinuedFloat` `figure.3a` becomes `figure.struct.96`), because
  latex-lab's `caption/step` plug now steps the counter and sets `\@currentHref`. This also
  happens with `\DocumentMetadata{}` without tagging; there hyperref is not loaded, so only
  the `.aux` and `.lof`/`.lot` names change. The other 6 jobs differ only in the
  `@tag@LastPage` structure count (+2 to +6): the new sub-float `Part` structures. Against v3.7
  on unpatched develop, the new code differs in exactly the same 34 jobs as v3.7 on patched
  develop, so those are kernel effects, not caption ones.
- **Structure tree:** differs only in three documents (both engines), all from subcaption
  v1.8 and the sockets `subfloat/begin|end`:

  | document | v3.7 sub-caption parents | new sub-caption parents |
  |---|---|---|
  | memoir class, tagged | …/Part/Part (×2) | …/Part/Div/Part (×2) |
  | continued sub-types, tagged | …/Part/Part (×3) | …/Part/Div/Part (×3) |
  | hyperref + cleveref, tagged | …/Part/Part (×4), …/Part/Div (×2, `\subcaptionbox`) | …/Part/Div/Part (×6) |

  The `Caption` and `Lbl` counts are unchanged everywhere.
- **Caption suite** (302 tests): pdfLaTeX 26 → 27 failures, LuaLaTeX 12 → 13; the only new
  failure is `issues/gitlab/issue_111.tex`. 250/248 common PDFs; text/positions differ only
  in issue_77; 6 `.aux` files differ (`test/tagging/`: basic, boxes, labelformat-empty,
  longtable, subcaption, tagging-off). After target normalisation four are identical, and
  boxes and subcaption differ only by the sub-float `Part`.
- **issue_111:** `\caption` in a `subtable` outside any float now raises the kernel's
  `\caption outside float` error instead of `\caption@Error`, which the test redefines to
  catch, so the test run halts. A further one-shot interception in `cmd/caption/before`
  could restore caption's error. I did not add it: it is a design decision and another
  dependency on the kernel's code layout. (Proposal O2 in version 2 is related.)
- **10 further documents** for the core and sub-caption changes, both kernels: on unpatched
  develop all 40 runs are identical; on patched develop 22 of 40. The rest differ by target
  names, by the sub-float `Part`, or (a sub-float outside a float) by the kernel error of
  issue_111, with the arguments typeset.

## 5. Whose definitions are active after `\begin{document}` (patched kernel)

`\meaning` of each macro after `\begin{document}` (pdfLaTeX), article with and without
`\usepackage{caption,subcaption}`. **caption** = caption's definition, unchanged = the same as
without caption, undef = not defined.

| setup | build | `\caption` | `\@caption` | `\@xfloat` | `\@xdblfloat` | `\@makecaption` | `\@float@HH` | `\@endfloatbox` |
|---|---|---|---|---|---|---|---|---|
| article, tag off | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| article, tag off | new | kernel† | unchanged | unchanged | unchanged | **caption** | undef | unchanged |
| article, tag on | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| article, tag on | new | kernel† | unchanged | unchanged | unchanged | **caption** | undef | unchanged |
| +hyperref, tag off | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| +hyperref, tag off | new | **caption** | **caption** | unchanged | unchanged | **caption** | undef | unchanged |
| +hyperref, tag on | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| +hyperref, tag on | new | kernel† | unchanged | unchanged | unchanged | **caption** | undef | unchanged |
| +float, tag off | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | unchanged | unchanged |
| +float, tag off | new | **caption** | **caption** | **caption**‡ | unchanged | **caption** | unchanged | unchanged |
| +float, tag on | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | unchanged | unchanged |
| +float, tag on | new | **caption** | **caption** | **caption**‡ | unchanged | **caption** | unchanged | unchanged |

† The kernel `\caption` with `\UseHookWithArguments{cmd/caption/before}{0}` in front, patched
in by the generic command hooks because caption adds code to that hook.
‡ The checking wrapper (`\caption@ORI@xfloat` plus the hooked flag): float.sty's `\@xfloat`
hides `\@float@begin@hook` one level down. setspace and floatrow get the same wrapper, also
on the client path (section 6, finding 14).

So with the plain kernel, latex-lab (tagging) or hyperref under `\DocumentMetadata`, caption no
longer redefines `\caption`, `\@caption`, `\@xfloat` or `\@xdblfloat`. Only `\@makecaption`
is still caption's, as (c) intends. With hyperref without `\DocumentMetadata` and with
float.sty, caption falls back to the v3.7 redefinitions: there is no public "kernel caption is
active" test, and hyperref and float.sty are not clients.

## 6. Further checks

Targeted checks in three areas (fallback, tagging, interfaces) found 18 issues. I reproduced
each one before deciding what to do with it. The fixes are six small commits; the head is then
**b4abaa9**. The CheckSums of caption.dtx, caption3.dtx, subcaption.dtx and
`source/fallback/v3.7/*.dtx` were not updated after these fixes.

| commit | change |
|---|---|
| 30cae0a | `\caption@ifkernelcaption` and `\caption@iffloathooks` no longer use `\if@tempswa` (#2) |
| a6d5e23 | v3.7 / v2.5 as fallback releases (`source/fallback/v3.7`, `caption_2026-10-04.sty`, `caption3_2026-10-04.sty`, tests in `test/fallback/caption_v3.7`) (#1) |
| 6e65f60 | subcaption uses the sockets `subfloat/begin|end` only with caption ≥ v3.8 (#3) |
| 1b3230b | in sub-floats, the copy of the kernel `\@caption` is used only when `\@caption` no longer uses `caption/listentry` (e.g. threeparttable) (#15) |
| 8a0eee0 | `\caption@client@@@makecaption` also takes the star from the kernel's `\if@captionstar` (#11, part) |
| b4abaa9 | `\@currentHref` is empty while the client step runs and is restored afterwards, unless the plug set a new one (#4) |

| # | issue (short) | outcome |
|---|---|---|
| 1 | `[=v3.7]` unknown; `[=2026-10-04]` selects v3.6 | **fixed**: both now load caption v3.7 + caption3 v2.5 without errors |
| 2 | `\if@tempswa` false after `\begin{document}` | **fixed**: all 200 `\meaning` dumps of the fallback matrix are byte-identical to v3.7, without filtering |
| 3 | subcaption sockets with caption `[=v3.6]` or a `latexrelease` roll-back | **fixed**: with `[=v3.6]` and roll-backs to 2023-06-01, 2024-06-01, 2025-06-01: 32 structures as with v3.7, `.aux` identical |
| 4 | `\captionof` + hyperref + tagging records the previous target (wrong /Ref in TOC/LOF) | **fixed**: the kernel `\refstepcounter` runs `recordtarget` after caption has suppressed hyperref's target, so `\@currentHref` is now empty during that step. /Ref mapping, warnings and errors are identical to v3.7 in both engines. The drop of 6 tagpdf warnings in section 4 was this bug. See G5 |
| 5 | LuaLaTeX `\subcaptionbox` content outside the tree | pre-existing (same in v3.7) |
| 6 | `\captionof` outside floats moved to the start of `Sect` | pre-existing |
| 7 | sub-float `Div` > `Part`, one level deeper; `\subcaption` in a plain minipage gets no `Part` | gap G1 (the `\subcaption` part is pre-existing) |
| 8 | longtable caption not tagged as `Caption` | pre-existing (latex-lab alone has none either) |
| 9 | two captions or minipage captions: kids in reverse order | pre-existing (latex-lab "firstkid" design) |
| 10 | wrapfigure `Caption` inside `P` | pre-existing (latex-lab does not support wrapfig) |
| 11 | client path depends on `\@dblarg` | **fixed in part**, gap G2: `\caption*` works without the `\@dblarg` interception; `\caption{}` and `\caption[]{x}` cannot be told apart, so the interception stays |
| 12 | `\ContinuedFloat` needs the step plug to call `\stepcounter` | gap G3 |
| 13 | listings: caption overwrites latex-lab's `\lst@makecaption`, `\@captype` undefined | pre-existing (v3.7 gives the same 2 errors); see G6 |
| 14 | `\@xfloat` wrapped with setspace and floatrow too | gap G4 (the wrapper acts only when the hook did not run) |
| 15 | sub-captions use a stale begin-document copy of `\@caption` | **fixed** |
| 16 | type passed through a global side channel in the listentry plug | gap G2 |
| 17 | `\if@skiphyperref` and the order inside `\refstepcounter` | gap G5 |
| 18 | v3.7's tagging code uses raw structure names, plug names, `\@current@float@struct`, `<type>.struct.<n>` | pre-existing, gap G7 |

### Gaps in the proposals

- **G1 (b, sub-float sockets):** the documentation says "one `Part` per sub-float with its
  `Caption` as first kid", but not how that combines with the minipage's own `Div`. Either
  `subfloat/begin` takes the place of the minipage structure (a documented role or key for
  "this minipage is a sub-float"), or the kernel offers a sub-float environment.
- **G2 (b):** `caption/listentry` cannot tell `\caption{}` from `\caption[]{x}`, or `[{}]` from
  an absent argument; a third argument or -NoValue- would help. There is also no documented
  place where `\@makecaption` code learns the type, the star and the list text. With both,
  caption could drop its `\@dblarg` interception, the global type side channel and the
  `\ignorespaces` strip.
- **G3 (b):** caption needs a documented "do not step / no target" flag that the
  `caption/step` plugs (kernel, latex-lab) honour, for `\ContinuedFloat`. The alternative is to
  document that every plug must step with `\stepcounter{#1}`.
- **G4 (a, open question 4):** a public conditional for "float hooks active" (false after a
  roll-back), and a documented way to know that `\@xdblfloat` runs the hook itself. caption's
  guards test `\@float@usehooks`, `\@float@begin@hook` and `\meaning\@xfloat`, and cannot see
  the hook through wrappers (float, floatrow, setspace).
- **G5 (b, lttagging):** with `\@skiphyperref` true, `\refstepcounter` still runs the
  `recordtarget` socket and records a stale `\@currentHref`. The flag of G3 should also
  suppress `recordtarget`, or `recordtarget` should only run when a target was set. caption
  then needs neither `\if@skiphyperref` nor the empty-`\@currentHref` code of b4abaa9.
- **G6 (d):** `\__tag_float_name:n` should fall back to `generic` when `\@captype` is
  undefined or empty (listings). caption3's private `Lbl` tagging for that case could then go.
- **G7 (c, lttagging, a/b):** caption needs a socket or plug for "caption typeset as one inline
  paragraph", so that plugs are not saved and restored by name, a public
  `\IfTaggingSocketExistsTF`, and a documented float link target ("after `float/begin`,
  `\@currentHref` is the float target").

### Runs after the fixes

- **Caption suite, TL 2026:** 273/252 PDFs; text/positions differ only in issue_77, `.aux` in
  none; failure lists identical (4 and 9). The 8 new tests in `test/fallback/caption_v3.7`
  pass.
- **Corpus:** TL 2026 and unpatched develop **0 / 78** each. Patched develop: only the
  `\captionof`-outside-floats documents changed (warnings, both engines) and are now
  identical to v3.7; totals errors 39 (4 jobs), caption W 24, tagpdf W 49, hyperref W 0,
  other W 9; per job the error and warning
  counts, errors and text are identical to v3.7; after target normalisation 72 / 78 are
  identical, and the other 6 differ by the sub-float `Part`.
- **Caption suite, patched develop:** identical to the run before the fixes; against v3.7,
  issue_111 is still the only new failure, with the same 6 tagging `.aux` differences.
- **Fallback matrix** (200+ jobs, three formats): `\meaning` dumps 0 / 200 differ. Remaining
  differences: `[=v3.7]` and `[=2026-10-04]` now load the fallback file (log only); KOMA's
  scrhack message moved by one line (the new `\DeclareRelease` line); LuaLaTeX memory
  statistics; in a tagged hyperref PDF the random tagpdf namespace UUID has one hex digit
  fewer, which shifts the xref offsets (no other difference, compared object by object).

## 7. Later changes (2026-10-06)

The kernel series was changed three times on 2026-10-06; its final state is latex2e branch
`poc-kernel-interfaces` of https://github.com/mark-vis/latex2e, head **de50ef859**, and is in
`kernel-patches/`. Below, "old kernel" is the patched develop of sections 4–6 and "new kernel"
the final series; "old client" is b4abaa9 and "new client" is 0ee2ded.

**(c) keeps the hook label.** latex-lab-float adds its `\@makecaption` code with the label
`latex-lab-testphase-float` again and documents it, with a `voids` rule as the preferred way
to disable it; new tests `float-025-makecaption-label` and `float-026-makecaption-voids`. The
new client disables the code with `\AddToHook{begindocument}[caption]{}` and
`\DeclareHookRule{begindocument}{caption}{voids}{latex-lab-testphase-float}` instead of
`\RemoveFromHook{begindocument}[latex-lab/float/makecaption]`; only `caption.sty` changes.

- latex-lab `config-float`, `config-table-pdftex`, `config-table-luatex`, `config-block`: the
  same `.diff` files before and after (`<PDF>` line only); `float-025`/`-026` pass in both
  engines and fail with the old (c).
- Classes (pdfLaTeX; acmart, mitthesis, asmeconf, asmejour; plain, `\DocumentMetadata{lang=en}`
  with and without hyperref, `tagging=on`; with and without caption; 23 documents): on the old
  kernel the five acmart documents with `\DocumentMetadata` and the two asmeconf documents with
  `tagging=on` gave "Cannot remove chunk 'latex-lab-testphase-float'" (with the old client and
  with TL's caption), and acmart printed "Fig. 1: First / Fig. 1: Starred" without caption. On
  the new kernel, with TL's caption and with the new client: no "Cannot remove chunk", and the
  captions are as on unpatched develop and TL ("Fig. 1. First / Starred"). The remaining
  differences to unpatched develop (in asmejour and mitthesis `\caption*` does not step; one
  more `Lbl` under tagging in acmart and asmeconf; acmart 14 instead of 10 tagging errors) are
  the same on both kernels.
- Corpus: old client on the old kernel against new client on the new kernel, **0 / 78**
  differ; the same on TL 2026 and unpatched develop (old against new client). Totals as after
  the fixes of section 6.
- Caption suite (310 tests, pdfLaTeX and LuaLaTeX), old client on the old kernel against new
  client on the new kernel: failure lists identical (27 / 13), 258 / 256 common PDFs,
  text/positions differ only in issue_77, 0 `.aux` differences, structure trees of the 286 PDFs
  under `test/` identical.

**Full base suite.** (a) and (b) now carry the `.tlg` lines of their release blocks and hooks
in the base tests that list all of them (13 roll-back tests in pdfTeX, LuaTeX and XeTeX,
`lthooks2-002`, `lthooks2-005`). (c) documents the label as kept for compatibility, and
`float-025` has `\START` before `\RemoveFromHook`, so a "Cannot remove chunk" warning shows up
as a difference. On a `git archive` of each of the four commits: base (default configuration,
all tests, three engines), `config-lthooks`, `config-lthooks2`, the other base configurations
and firstaid (`build`, `config-TU`) all pass; in latex-lab `config-float` only the tests that
print the structure differ, in the `<PDF>` line (see "About the `<PDF version="2.0">` line" in
`PROPOSALS.md`). The built kernel differs only in the documentation of
`latex-lab-float.dtx`; corpus with the new client,
before and after: **0 / 78** differ, totals as after the fixes of section 6.

**Wide `\caption*` and threeparttable.** (b): latex-lab's `\@makecaption` gives the label
tagging sockets the plugs `nolabel` for `\caption*` instead of `noop` (with `noop` a
`\caption*` wider than the line gave a `P` inside a `P` and the tagpdf error "para hooks
differ"); new test `float-028`. (c): an open marked-content chunk counts as the caption
paragraph only if the caller has not said that it uses the label sockets before the
paragraph, as latex-lab's `\@makecaption` now does; otherwise every caption in a tagged
threeparttable gives that tagpdf error, which develop does not give; new test `float-027`.

- On `git archive`s of (a)+(d)+(b) and of the whole series: base (603 tests, three engines),
  `config-lthooks`, `config-lthooks2`, firstaid, and for the series also the 7 other base
  configurations: all pass; latex-lab `config-float`: only the `<PDF>` line.
- Tagged threeparttable and `\caption*` documents (20 documents, pdfLaTeX and LuaLaTeX): the
  error counts of develop (0, or develop's own `tablenotes` error); structure trees equal to
  those with version 2 of (b) in all 40 runs, and to develop in all runs without `\caption*`.
- Corpus with the new client, before and after this step: **0 / 78** differ.
