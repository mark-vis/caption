# PoC results: caption on the kernel interfaces (a)–(d), integrated

Date: 2026-10-05. POC = this directory. Nothing was pushed or posted.

> **Taken with the renamed label (2026-10-06).** Every measurement in sections 1–6 on the
> patched kernel (`kernel/`) was taken with the first version of proposal (c), which moved
> latex-lab's `begindocument` code for `\@makecaption` to the new hook label
> `latex-lab/float/makecaption`, and with a client that removed it by that label. That
> rename broke acmart, mitthesis, asmeconf and asmejour (they remove the code by the old
> label `latex-lab-testphase-float`). The kernel series and the client were changed on
> 2026-10-06; section 7 has the re-measurement. The measurements on TeX Live and on
> unpatched develop are not affected.

## 1. Integration

- New worktree `cap-poc/` on branch `poc-kernel-interfaces` (was caption-v3.7, 122696d).
- `git merge --no-ff poc-ki-core` → bdfc46f, then `git merge --no-ff poc-ki-sub` → **ce43fdf** (HEAD).
  Both merges had no conflicts: core changes only `caption.dtx` and `caption3.dtx`, sub changes only `subcaption.dtx`.
  The merged files are byte-identical to the branch versions, so the CheckSums of both branches still hold
  (caption 3532, caption3 3995, subcaption 620).
- Built with `build.sh cap-poc sty-poc`. Compared with `sty-ref`, only `caption.sty`, `caption3.sty` and
  `subcaption.sty` differ (plus logs and dtx copies). All fallback files and the other packages are identical.
- **No integration fix commits were needed.** Nothing in the measurements below comes from core and sub
  interacting badly. Every difference was already found on the core or the sub branch.

## 2. Fallback identity (kernels without the interfaces)

### Caption test suite (`run-suite-parallel.sh`, 6 jobs, 6 shards, pdflatex+lualatex)

The trees are scratch copies in `suite/trees/{ref,poc}`: cap-ref with sty-ref in `tex/`, and cap-poc with sty-poc in `tex/`.
I compared them with `suite/cmpsuite-poc.py`. It is cmpsuite3.py generalised to take the run names as arguments, and it uses the same
signature: `pdftotext -bbox` without Date lines, plus the .aux md5. It also compares the .fail lists.

| kernel | engine | testcases | failures v3.7 | failures PoC | PDFs compared | text/pos differ | aux differ |
|---|---|---|---|---|---|---|---|
| TL 2026 | pdflatex | 302 | 4 | 4 (same list) | 273 | 1* | 0 |
| TL 2026 | lualatex | 302 | 9 | 9 (same list) | 252 | 1* | 0 |
| kernel-stock | pdflatex | 302 | 26 | 26 (same list) | 251 | 1* | 0 |
| kernel-stock | lualatex | 302 | 12 | 12 (same list) | 249 | 1* | 0 |

\* `issues/gitlab/issue_77.pdf`: ltugboat prints the compile time ("10:47" against "10:49"). It is not a real difference.

**Result: identical on TL 2026 and on kernel-stock.**
The extra failures on kernel-stock compared with TL (babel frenchpro/hungarian/magyar, thesis/fonts, …) come from the custom
formats, for example missing hyphenation patterns. v3.7 and the PoC have them alike.

### Corpus (`corpus/run.sh`, 17 documents, 78 variant×engine jobs per kernel, 3 runs each)

| comparison | jobs differing (status, errors, warnings, text, aux, lists, out, struct) |
|---|---|
| ref-tl vs poc-tl | **0 / 78** |
| ref-stock vs poc-stock | **0 / 78** |

## 3. Patched kernel (`kernel/`, series 0001–0004; renamed label, see section 7)

### Corpus totals (summed over the 78 jobs)

| build | errors | jobs with errors | caption W | tagpdf W | hyperref W | other W |
|---|---|---|---|---|---|---|
| v3.7 on stock | 116 | 4 | 24 | 107 | 0 | 9 |
| v3.7 on patched | 39 | 4 | 24 | 49 | 0 | 9 |
| **PoC on patched** | **39** | 4 | 24 | **43** | 0 | 9 |

- **No new errors.** errors.txt is byte-identical to ref-patched in every job. The remaining errors are the known v3.7/kernel cases:
  floatsty-H-tag (float.sty `\newfloat` type unknown to tagging, 10/13) and listings-captions-tag (8, empty `\@captype`).
- (Superseded by section 6, finding 4: this drop was a bug and is gone.) tagpdf warnings drop by 6: captionof-outside-floats-tag goes from 4 to 1 per engine. The three
  "Destination 'figure.1'/'figure.2'/'figure.caption.3' has no related structure" warnings are gone. The destinations
  and `\newlabel`s are unchanged. The same improvement shows in sub-work's subfloat-edge.tex.
- **Text (pdftotext -layout) is identical to ref-stock and to ref-patched in all 78 jobs.**

### aux / lists (PoC-patched against ref-patched)

28 of 78 jobs differ in aux or lists. With `corpus/tgtnorm.py`, which maps link target names `<type>.N` and `<type>.struct.N` to
one token and drops tagpdf mcid records:

- 72 of 78 jobs are identical. The **only list/label difference is the target name**: `figure.N` becomes `figure.struct.N`
  (also `figure.3a` becomes `figure.struct.96` for a `\ContinuedFloat`). This happens because latex-lab's caption/step plug now steps
  the counter and sets `\@currentHref`. Besides the tagged documents (a known open issue of the core branch), it **also applies to
  `\DocumentMetadata{}` without tagging** (star-and-empty-listentry-meta, typeopts-figure-table-meta). There, hyperref is
  not loaded and the PDF has no destinations, so only the .aux and .lof/.lot names change.
- The other 6 jobs (memoir-class-tag, subcaption-continued-subtypes-tag, subcaption-hyperref-cleveref-tag, ×2 engines)
  differ only in the `@tag@LastPage` struct count (+2 to +6). Those are the new sub-float `Part` structures.

Against **ref-stock**, after the same normalisation, PoC-patched differs in exactly the same 34 jobs as ref-patched does
(the same set, checked with diff). So those are kernel effects (tagpdf records, write order), not caption ones.

### Structure tree (PoC-patched against ref-patched)

struct.txt differs only in memoir-class-tag, subcaption-continued-subtypes-tag and subcaption-hyperref-cleveref-tag
(both engines). In all three, the cause is subcaption v1.8 (socket `subfloat/begin|end`):

| document | v3.7 sub-caption parents | PoC sub-caption parents |
|---|---|---|
| memoir-class-tag | …/Part/Part (×2) | …/Part/Div/Part (×2) |
| subcaption-continued-subtypes-tag | …/Part/Part (×3) | …/Part/Div/Part (×3) |
| subcaption-hyperref-cleveref-tag | …/Part/Part (×4), …/Part/Div (×2, `\subcaptionbox`) | …/Part/Div/Part (×6) |

The Caption and Lbl counts are unchanged everywhere. Every other job has an identical structure tree, so (a), (b) and (c) do not
change the tree. This agrees with the result on the core branch.

### Caption suite on the patched kernel (sty-ref against sty-poc)

| engine | testcases | failures v3.7 | failures PoC | new failures | PDFs | text/pos differ | aux differ |
|---|---|---|---|---|---|---|---|
| pdflatex | 302 | 26 | 27 | `issues/gitlab/issue_111.tex` | 250 common | 1 (issue_77 time) | 6 |
| lualatex | 302 | 12 | 13 | `issues/gitlab/issue_111.tex` | 248 common | 1 (issue_77 time) | 6 |

- **issue_111** (the only new failure): in Test 1, `\caption` sits in a `subtable` outside any float. The PoC uses the kernel `\caption` here.
  It raises the kernel's `\@latex@error{\caption outside float}` instead of `\caption@Error`, which the test redefines to catch,
  and the halting test run produces no PDF. This is a known open issue of the core branch (new path, `\caption` outside float).
  A possible fix is one more one-shot interception: in cmd/caption/before with `\@captype` undefined, issue
  `\caption@OutsideFloat\caption`, swallow the kernel's error branch and gobble the arguments as v3.7 does. I did not apply it,
  because it is a design decision and another dependency on kernel code layout.
- aux differs in test/tagging/{basic, boxes, labelformat-empty, longtable, subcaption, tagging-off}. After normalising target names,
  basic, labelformat-empty, longtable and tagging-off are identical. boxes and subcaption differ only in the LastPage struct count
  (sub-float Part). Their structsum shows …/Part/Part becoming …/Part/Div/Part, and the `\subcaptionbox` …/Part/Div becoming …/Part/Div/Part.
- The full lists are in `suite/run-patched/poc-{pdflatex,lualatex}.fail`; the comparison is in `suite/cmp-patched.txt`.

### Extra integration check (core's own docs and sub's edge docs, combined build)

`sub-work/cmp.py --ref sty-ref --new sty-poc --kernels kernel,stock` on work-core/docs (7) and sub-work/extra (3),
`integ/cmp.txt`:
- On stock, all 40 runs are identical.
- On patched, 22 of 40 are identical. The rest are:
  - lists differ only by target names (a-setspace, b-classes, b-tpt, b-star-cont-nohyp tagged);
  - struct differs from the sub-float Part (b-star-cont*, subfloat-edge, subfloat-tabular);
  - subfloat-outside gives the kernel error instead of caption's, and the arguments are typeset (the same issue as issue_111);
  - subfloat-edge loses one tagpdf warning ("Destination 'figure.caption.3' has no related structure").

## 4. Audit: whose definitions are active after `\begin{document}` (patched kernel)

`audit/` writes `\meaning` of each macro after `\begin{document}` (pdflatex) for article with and without
`\usepackage{caption,subcaption}`, in three setups (plain, +hyperref, +float), each with tagging off and on.
Each cell says how the meaning compares with the same document without caption/subcaption:
**caption** = caption's definition (meaning contains `caption@`), unchanged = the same as without caption,
undef = not defined.

| setup | build | `\caption` | `\@caption` | `\@xfloat` | `\@xdblfloat` | `\@makecaption` | `\@float@HH` | `\@endfloatbox` |
|---|---|---|---|---|---|---|---|---|
| article, tag off | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| article, tag off | PoC | kernel† | unchanged | unchanged | unchanged | **caption** | undef | unchanged |
| article, tag on | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| article, tag on | PoC | kernel† | unchanged | unchanged | unchanged | **caption** | undef | unchanged |
| +hyperref, tag off | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| +hyperref, tag off | PoC | **caption** | **caption** | unchanged | unchanged | **caption** | undef | unchanged |
| +hyperref, tag on | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | undef | unchanged |
| +hyperref, tag on | PoC | kernel† | unchanged | unchanged | unchanged | **caption** | undef | unchanged |
| +float, tag off | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | unchanged | unchanged |
| +float, tag off | PoC | **caption** | **caption** | **caption**‡ | unchanged | **caption** | unchanged | unchanged |
| +float, tag on | v3.7 | **caption** | **caption** | **caption** | **caption** | **caption** | unchanged | unchanged |
| +float, tag on | PoC | **caption** | **caption** | **caption**‡ | unchanged | **caption** | unchanged | unchanged |

† This is the kernel `\caption` with `\UseHookWithArguments{cmd/caption/before}{0}` in front. The kernel's generic-cmd-hook
machinery patched it in because caption adds code to that hook. It is not a caption definition.
‡ This is the checking wrapper (`\caption@ORI@xfloat` plus the hooked flag). float.sty's `\@xfloat` hides `\@float@begin@hook` one level down.
(Correction from the review round: setspace and floatrow get the same checking wrapper, also on the client path. See section 6, finding 14.)

Summary: with the plain kernel, latex-lab (tagging) or hyperref under `\DocumentMetadata`, the PoC no longer redefines
`\caption`, `\@caption`, `\@xfloat` or `\@xdblfloat`. Only `\@makecaption` is still caption's, which (c) intends.
With hyperref without `\DocumentMetadata` (still the most common setup) and with float.sty, the PoC falls back to the v3.7 redefinitions
(proposal gap (b): there is no public "kernel caption is active" test, and hyperref and float.sty are not clients).
caption never touches `\@float@HH` or `\@endfloatbox`, either in v3.7 or in the PoC.

## 5. Open points (no new ones from the integration)

1. issue_111 / `\caption` outside a float: kernel error instead of caption's error, and the arguments are typeset. This is the only new suite failure.
2. Link target names `<type>.N` become `<type>.struct.N` in .aux/.lof on the patched kernel, also with `\DocumentMetadata{}` without tagging.
3. Sub-floats are now Div > Part (one level deeper than v1.7's Part, but `\subcaptionbox` gains a Part).
4. hyperref without `\DocumentMetadata`, and float.sty: the v3.7 path (redefinitions) is still taken.
5. The pre-existing errors (floatsty-H-tag, listings-captions-tag) are unchanged.

## 6. Review round (2026-10-05)

A review in three areas (fallback, tagging, interfaces) gave 18 findings. I reproduced each one before deciding what to do with it.
The fixes are six small commits on `poc-kernel-interfaces` (author Mark Vis, noreply). HEAD is now **b9111ce**.
The build before the review is kept as `sty-poc-r0/`, and `sty-poc/` is the new build.
CheckSums are **not** updated in this round. That affects caption.dtx, caption3.dtx, subcaption.dtx and the new source/fallback/v3.7/*.dtx, and is left for later.

| commit | change |
|---|---|
| 30cae0a | caption: `\caption@ifkernelcaption` and `\caption@iffloathooks` no longer use `\if@tempswa` (#2) |
| a6d5e23 | caption, caption3: v3.7 / v2.5 as fallback releases (`source/fallback/v3.7`, `caption_2026-10-04.sty`, `caption3_2026-10-04.sty`, tests in `test/fallback/caption_v3.7`) (#1) |
| 6e65f60 | subcaption: uses the sockets subfloat/begin\|end only when `\caption@ifclient` exists, i.e. with caption ≥ v3.8 (#3) |
| 1b3230b | caption: in sub-floats, the copy of the kernel `\@caption` is used only when `\@caption` no longer uses caption/listentry (e.g. threeparttable) (#15) |
| 8a0eee0 | caption: `\caption@client@@@makecaption` also sets the star flag from the kernel's `\if@captionstar` (#11, part) |
| b9111ce | caption: `\@currentHref` is empty while the client step runs and is restored afterwards, unless the plug set a new one (#4) |

### Per finding

| # | finding (short) | reproduced | outcome |
|---|---|---|---|
| 1 | `[=v3.7]` unknown; `[=2026-10-04]` selects v3.6 | yes (tl, stock) | **fixed** (a6d5e23). `[=v3.7]` and `[=2026-10-04]` now load caption v3.7 + caption3 v2.5 without errors. `caption_2026-10-04.sty` equals sty-ref's caption.sty except for the release lines and `[=2026/10/04]` for caption3. |
| 2 | `\if@tempswa` false after `\begin{document}` | yes | **fixed** (30cae0a). TEMPSWA=true. All 200 `.mng` dumps of the review-fallback matrix are now byte-identical to sty-ref, with no filtering. |
| 3 | subcaption sockets with caption `[=v3.6]` / latexrelease rollback | yes (34 vs 32 structs) | **fixed** (6e65f60). v36-tag-sub and relp-tag-{2023,2024,2025}-06-01 on the patched kernel: 32 structs, and the .aux is identical to sty-ref. |
| 4 | `\captionof` + hyperref + tagging records the previous target (TOC/LOF /Ref wrong) | yes (both engines) | **fixed** (b9111ce). The kernel `\refstepcounter` runs recordtarget after caption has suppressed hyperref's target, so `\@currentHref` is now empty during that step (tagpdf does not record an empty name). t07-refmap, c01-corpus-captionof, t04, t05, t13: /Ref mapping, warnings and errors are now identical to v3.7 on both engines. t08 is the same up to struct numbers, and t12 (no hyperref) is still better than v3.7. The "−6 tagpdf warnings" from section 3 were this bug and are gone. See proposal gap G5. |
| 5 | lualatex `\subcaptionbox` content outside the tree | yes | **pre-existing** (same in v3.7, luatex attributes fixed at boxing time) |
| 6 | `\captionof` outside floats hoisted to the start of Sect | yes | **pre-existing** (struct.txt identical for ref and poc) |
| 7 | sub-float Div > Part, one level deeper; `\subcaption` in a plain minipage gets no Part | yes | **proposal gap** G1 (the `\subcaption` part is pre-existing) |
| 8 | longtable caption not tagged as Caption | yes | **pre-existing** (ref = poc; latex-lab alone has no Caption either) |
| 9 | two captions or minipage captions: Note kids in reverse order | yes | **pre-existing** (kernel/latex-lab "firstkid" design, the same without caption) |
| 10 | wrapfigure Caption inside P | yes | **pre-existing** (ref = poc, latex-lab does not support wrapfig) |
| 11 | client path depends on `\@dblarg` | yes | **fixed in part + proposal gap** G2. `\caption*` now works without the `\@dblarg` interceptor (dblarg-layout prints only "Starred", at the same position as dblarg-control). `\caption{}` against `\caption[]{x}` cannot be told apart from caption/listentry, so the interceptor stays. |
| 12 | `\ContinuedFloat` needs the step plug to call `\stepcounter` | yes ("Figure 2 … (continued)", error) | **proposal gap** G3 |
| 13 | listings: caption overwrites latex-lab's `\lst@makecaption`, `\@captype` undefined → errors | yes (2 errors) | **pre-existing** (v3.7 gives the same 2 errors on the patched kernel). The (d) fallback suggestion is recorded as G6. |
| 14 | `\@xfloat` wrapped with setspace and floatrow too | yes | **proposal gap** G4 (the wrapper is intended and only acts when the hook did not run). RESULTS §4 is corrected. A lazy check in cmd/caption/before would move the hypcap anchor for classes that bypass `\@xfloat`, so it is not done in the PoC. |
| 15 | sub-captions use a stale begin-document copy of `\@caption` | yes | **fixed** (1b3230b). subcap-copy now shows ATCAPTION for both the subfigure and the main caption. |
| 16 | type via a global side channel in the listentry plug, `\@gobble` of `\ignorespaces` | design (code reading + hook test) | **proposal gap** G2 (no documented way to learn the type, star or list text at `\@makecaption`). The generic hook cmd/@caption/before is just as much an internal layout, so I did not switch to it. wontfix in the PoC. |
| 17 | `\if@skiphyperref` and the order inside `\refstepcounter` | code reading, confirmed | **proposal gap** G5 (fix #4 adds the same kind of dependency on recordtarget) |
| 18 | v3.7 tagging code uses raw tagsupport/ names, plug names, `\@current@float@struct`, `<type>.struct.<n>` | code reading, confirmed (unchanged v3.7 lines) | **pre-existing / proposal gap** G7 |

### Proposal gaps (to add to PROPOSALS.md open questions; no extra internals in caption)

- **G1 (b, subfloat sockets):** the socket documentation says "one Part per sub-float with its Caption as first kid", but it does not say how that combines with the minipage's own Div. Either subfloat/begin should take the place of the minipage structure (for example a documented role or key for "this minipage is a sub-float"), or the kernel should offer a sub-float environment interface.
- **G2 (b, caption interface):** caption/listentry cannot tell `\caption{}` from `\caption[]{x}`, or `[{}]` from an absent argument. A third argument or -NoValue- for an absent optional argument would help. There is also no documented place where `\@makecaption` code can learn the type, star state and list text, for example a documented `cmd/@caption/before` with arguments or `\@currentcaptiontype`. With both, caption could drop its `\@dblarg` interceptor, the global type side channel and the `\ignorespaces` strip.
- **G3 (b):** we need a documented "do not step / no target" flag that the caption/step plugs (kernel, latex-lab) honour, for `\ContinuedFloat`. The alternative is to document that every plug must step with `\stepcounter{#1}`.
- **G4 (a, open question 4):** a public conditional for "float hooks active" (false after a rollback), and a documented way to know that `\@xdblfloat` runs the hook itself. caption's guards currently test `\@float@usehooks`, `\@float@begin@hook` and `\meaning\@xfloat`, and they cannot see the hook through wrappers (float, floatrow, setspace).
- **G5 (b/lttagging):** with `\@skiphyperref` true, `\refstepcounter` still runs the recordtarget socket and records a stale `\@currentHref`. The "no target" flag from G3 should also suppress recordtarget, or recordtarget should only run when the target socket really set a target. caption then needs neither `\if@skiphyperref` nor the empty-`\@currentHref` trick from b9111ce.
- **G6 (d):** `\__tag_float_name:n` should fall back to `generic` when `\@captype` is undefined or empty (listings). caption3's private Lbl tagging for that case could then go.
- **G7 (c, lttagging, a/b):** we need a socket or plug for "caption typeset as one inline paragraph" so plugs are not saved and restored by name, a public `\IfTaggingSocketExistsTF`, and a documented float link target ("after float/begin, `\@currentHref` is the float target").

### Re-runs after the fixes

- **Fallback-identity suite, TL 2026** (`suite/run-tl-r1`, poc only, compared with the ref runs of `suite/run-tl`): pdflatex 273 common PDFs and lualatex 252, with text/pos differing only in issue_77 (the time) and aux differing in 0. The failure lists are identical (4 and 9). The 8 new tests in `test/fallback/caption_v3.7` pass. The v3.7 fallback `subcaption.pdf` is identical to sty-ref's `test/subcaption/subcaption.pdf`.
- **Corpus, all three kernels** (`corpus-out/poc-{tl,stock,patched}-r1`):
  - ref-tl against poc-tl-r1: **0 / 78** jobs differ. ref-stock against poc-stock-r1: **0 / 78**.
  - patched: poc-patched (before) against poc-patched-r1 differs only in captionof-outside-floats-tag (warnings, ×2 engines), which are now identical to ref-patched. Totals: errors 39 (4 jobs), caption W 24, tagpdf W **49** (= v3.7 on patched), hyperref W 0, other W 9. Columns 1–9 of summary.tsv (status, errors and warning counts per job) are identical to ref-patched. errors.txt and text.txt are identical to ref-patched in all jobs. With target normalisation, 72 / 78 jobs are identical, and the remaining 6 are the sub-float Part (as before).
- **Caption suite, patched kernel** (`suite/run-patched-r1`): identical to the PoC before the review (0 aux and 0 text differences, same failure lists). Against v3.7 the result is unchanged: issue_111 is the only new failure, and there are 6 tagging aux differences.
- **review-fallback matrix** (all 200+ jobs, tl/stock/dev, rerun for poc): `t.mng` 0 / 200 differ. cmp2 differences that remain:
  - v37 and date20261004 now load the v3.7 fallback file, so only the log differs (the fix).
  - koma/scrhack: tocbasic's "prevented on line 53/54" moved by one line, because of the new `\DeclareRelease` line.
  - lualatex memory statistics.
  - tag-hyp-all/tagging t.pdf: the random tagpdf namespace UUID has one hex digit fewer, which shifts the xref offsets. Objects compared one by one show no other difference.
- **review-tagging / review-interfaces checks:** rerun as listed per finding above. step-plug (#12) and robust-caption (#17) are unchanged, as expected for proposal gaps.

## 7. Update 2026-10-06: proposal (c) keeps the hook label (found while revising proposal (b))

- Kernel: latex2e branch `poc-kernel-interfaces` (https://github.com/mark-vis/latex2e). The fix of poc-b2 90fe37d7c was squashed
  into the (c) commit, now **5e0a9fc88**: latex-lab-float adds the code with the label
  `latex-lab-testphase-float` again and documents it (with a `voids` rule as the preferred
  way to disable it); new tests `float-025-makecaption-label`, `float-026-makecaption-voids`
  (their `.tlg` saved again for the v1 `\caption*`, which passes an empty label).
  `kernel-patches/0004-*.patch` regenerated with `git format-patch`; 0001–0003 unchanged.
  Built as `kernel-r4` (formats and inputs; compared with `kernel`, only
  `latex-lab-float.dtx`/`latex-lab-testphase-float.sty` differ, plus the branch's
  `latexrelease.sty`, which `kernel/` lacked).
- Client: caption.dtx (commit eb35223 on this branch) disables the code with
  `\AddToHook{begindocument}[caption]{}` +
  `\DeclareHookRule{begindocument}{caption}{voids}{latex-lab-testphase-float}` instead of
  `\RemoveFromHook{begindocument}[latex-lab/float/makecaption]` (as caption poc-b2 0712913).
  Built as `sty-poc-ki-r4`; only `caption.sty` differs from `sty-poc-ki`.
- l3build (latex-lab, exports of the branch before and after): `config-float`,
  `config-table-pdftex`, `config-table-luatex`, `config-block` give the same `.diff` files with
  the same content (`<PDF>` line only); float-025/026 pass in both engines and fail on the old
  (c).
- Classes (pdfLaTeX, 3 runs; acmart, mitthesis, asmeconf, asmejour × plain,
  `\DocumentMetadata{lang=en}` with and without hyperref, `tagging=on`, each with and without
  caption; 23 documents): on `kernel/` the five acmart documents with `\DocumentMetadata` and
  the two asmeconf documents with `tagging=on` gave "Cannot remove chunk
  'latex-lab-testphase-float'" (with sty-poc-ki and with TL's caption), and acmart printed
  "Fig. 1: First / Fig. 1: Starred" without the client; mitthesis and asmejour gave the same
  output on `kernel/` and `kernel-r4`. On `kernel-r4`, with TL's caption and with `sty-poc-ki-r4`: no "Cannot remove
  chunk" in any job, captions as on kernel-stock and TL ("Fig. 1. First / Starred"); the
  remaining differences to kernel-stock (asmejour/mitthesis `\caption*` does not step, one
  more `Lbl` under tagging in acmart/asmeconf, acmart 14 instead of 10 tagging errors) are the
  same on `kernel/` and on `kernel-r4`.
- Corpus (78 jobs, 3 runs): sty-poc-ki on `kernel/` against sty-poc-ki-r4 on `kernel-r4`:
  **0 / 78** differ (status, errors, warnings, text, aux, lists, out, struct); the same on TL
  and on kernel-stock (sty-poc-ki against sty-poc-ki-r4). Totals on kernel-r4 as in section 6:
  errors 39, caption W 24, tagpdf W 49, hyperref W 0, other W 9.
- Caption suite (310 tests, pdfLaTeX + LuaLaTeX): a518ec6 + sty-poc-ki on `kernel/` against
  eb35223 + sty-poc-ki-r4 on `kernel-r4`: failure lists identical (27 / 13), 258 / 256 common
  PDFs, text/positions differ only in issue_77 (the time), 0 `.aux` differences, structure
  trees of the 286 PDFs under `test/` identical.
- Scripts and outputs: `b2-revision/scripts/r4-fix/m3-label/` (SUMMARY.txt there).

## 8. Update 2026-10-06: the series passes the full base suite; (c) in its final form

- Kernel: latex2e branch `poc-kernel-interfaces` rewritten again, head **8a937c600**:
  - (a) and (b) now carry the `.tlg` lines of their release blocks and hooks in the base
    tests that list all of them (13 roll-back tests in pdfTeX, LuaTeX and XeTeX,
    `lthooks2-002`, `lthooks2-005`). These updates existed only on the (b) v2 branch, so
    before this the full base suite failed on every patch of the series.
  - (c) also contains the round-3 fixup of the (b) v2 branch (62eec6829): the label
    `latex-lab-testphase-float` is documented as kept for compatibility (not as "must not
    change"), and `float-025` has `\START` before `\RemoveFromHook`, so a "Cannot remove
    chunk" warning shows up as a difference.
  - `kernel-patches/0001`–`0004` regenerated with `git format-patch`.
- l3build on a `git archive` of each of the four commits: base (default configuration, all
  tests, three engines), `config-lthooks`, `config-lthooks2` and the other base
  configurations, firstaid (`build`, `config-TU`): all pass; latex-lab `config-float`: only
  the tests that print the structure differ, in the local `<PDF>` line.
- Built as `kernel-r5`: inputs identical to `kernel-r4` except
  `latex-lab-float.dtx` (documentation only); base sources identical. Corpus (78 jobs,
  3 runs) with `sty-poc-ki-r4`: kernel-r4 against kernel-r5 **0 / 78** differ; totals
  errors 39, caption W 24, tagpdf W 49, hyperref W 0, other W 9 (as in section 7). The
  caption client (`eb35223`) is unchanged and still pairs with `kernel-r4`/`kernel-r5`, not
  with `kernel/`.

## 9. Update 2026-10-06: no new tagpdf errors for wide `\caption*` and threeparttable

- latex2e `poc-kernel-interfaces` rewritten again (head `de50ef859`); (a) and (d) unchanged.
  - (b): latex-lab's `\@makecaption` gives the label tagging sockets the plugs `nolabel`
    for `\caption*` instead of `noop` (with `noop` a `\caption*` wider than the line gave
    a `P` inside a `P` and the tagpdf error "para hooks differ"). New test `float-028`.
  - (c): an open marked content chunk counts as the caption paragraph only if the caller
    has not said that it uses the label sockets before the paragraph, as latex-lab's
    `\@makecaption` now does. Before, every caption in a tagged threeparttable gave the
    tagpdf error, which develop does not give. New test `float-027`.
  - Both changes come from the (b) v2 branch, which now builds on this (c) unchanged.
  - `kernel-patches/0003` and `0004` regenerated (0001/0002 unchanged).
- l3build on `git archive`s of (a)+(d)+(b) and of the whole series: base (603 tests, three
  engines), `config-lthooks`, `config-lthooks2`, firstaid; for the series also the 7 other
  base configurations: all pass; latex-lab `config-float`: only the local `<PDF>` line.
- Rebuilt `kernel-r5`: only `latex-lab-float.dtx` and `latex-lab-testphase-float.sty`
  differ. Tagged threeparttable and `\caption*` documents (20 documents, pdfLaTeX and
  LuaLaTeX): the error counts of develop (0, or develop's own `tablenotes` error);
  structure trees equal to the (b) v2 kernel in all 40 runs, and to develop in all runs
  without `\caption*`. Corpus (78 jobs) with `sty-poc-ki-r4`: old against new `kernel-r5`
  **0 / 78** differ (4 jobs that timed out under load were rerun).

