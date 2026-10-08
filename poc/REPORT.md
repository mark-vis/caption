# caption4 proof of concept: results

2026-10-03. Branch `poc-caption4` (on top of `fixes-combined`), folder `poc/`.
Kernel and latex-lab survey: `survey/kernel-survey.md`.

## Summary

The core of caption/subcaption can be made **compatible with tagged PDF** with a
small, local change to the existing code: roughly 55 lines in caption.sty and 40 in
caption3.sty, using the kernel's tagging sockets. Everything else stays the same.
Existing documents produce identical output with tagging off. With tagging on, they
now produce the output they get without tagging, instead of losing their settings.
That is the most valuable result, because tagging is where the bundle is heading
for a hard break.

Getting rid of *all* redefinitions of kernel internals is **not possible yet**. The
kernel has no hook at the start of a float, and no caption interface (`\caption*`,
list-entry control, sub-captions). Those would have to come from the kernel. The PoC shows
exactly which interfaces are missing (see "What the kernel would need").

## What was built

- `poc/tex/caption4.sty`: the core of caption.sty v3.6p (without the 20 package
  adaptations, except hyperref/hypcap and longtable), plus the changes below.
- `poc/tex/subcaption4.sty`: subcaption v1.6c (with the #184 label-hook fix),
  loading caption4.
- `poc/tex/caption3.sty`: caption3 v2.4e plus tagging of measurement and label.
- `poc/harness/run.py`: compiles each test document with caption.sty (reference) and
  caption4, with pdfLaTeX and LuaLaTeX, with and without `\DocumentMetadata{tagging=on}`.
  It compares every word with its position (tolerance 1.5 pt under tagging), the
  lists (LoF/LoT/LoL), the `\newlabel` data, errors, new warnings and the structure tree.
- `poc/tests/`: 11 comparison documents (basic, type options, `\captionof`,
  ContinuedFloat, hyperref, newfloat, `\DeclareCaption…`, phantom/listentry,
  subfigure + amsmath + hyperref, `\subcaptionbox`, `list=true` + `\caption*`).

## Changes compared to caption.sty

| Change | Interface used |
|---|---|
| Caption wrapped in `caption/begin{<parent float>}` … `caption/end` | kernel tagging sockets (lttagging, 2024-11), plugged by latex-lab |
| Label tagged as `Lbl` inside the caption paragraph | tagpdf `\tag_struct_begin:n`, `\tag_mc_end_push:` / `\tag_mc_begin_pop:n` |
| No tagging while caption3 measures (single-line check, label width) | `\SuspendTagging` / `\ResumeTagging` |
| caption3's internal `\parbox` gets no Div/Part of its own; the outer paragraph is not tagged, the caption paragraph inside is | latex-lab sockets `parbox/before`, `parbox/after`, `para/restore` (assigned locally) |
| Sub-captions stay in their sub-figure; main caption becomes first kid of the float | `\@current@float@struct` (latex-lab) only for main captions |
| Under tagging: hypcap uses latex-lab's float target `<type>.struct.<n>` and the counter is stepped without an extra target | `\@kernel@refstepcounter`, latex-lab's float target |
| `\@makecaption` is set again at `\begin{document}` | latex-lab overwrites it there |

## Results

| Check | caption.sty v3.6p | caption4 |
|---|---|---|
| Harness, tagging off (11 docs × 2 engines) | reference | **22/22 identical** |
| Harness, tagging on, compared with caption.sty without tagging | **0/22**: settings lost (`labelsep`, `format=hang`, fonts, …), `\caption*` gets a number ("Figure 2: …"), captions 3.6 pt lower | **22/22 identical** |
| Structure | one `Caption` per float; subcaptions not tagged; warning "Destination 'figure.caption.N' has no related structure" (tagging-project issue #85) | `Caption` with `Lbl` for every caption; subcaptions as `Caption` inside their sub-figure; #85 warning gone |
| Full test suite (280 + 6 new tests) with caption4 renamed to caption | 4 failures (pdfLaTeX), all also in stock | 10: the same 4 + 6 new, all adaptations left out on purpose: floatrow (3), float package (2), beamer (1) |

Two tagging warnings remain, both also with caption.sty and both outside caption's
own responsibility:
- "Destination 'figure.N' has no related structure" for `\captionof` outside a float.
- "Parent-Child 'Link' --> 'Link'" when a caption contains `\subref` (a link inside a
  link in the List of Figures).

## What is still patched

Global redefinitions at `\begin{document}`:
- `\caption`, `\@caption`: needed for `\caption*`, list entries, ContinuedFloat and
  sub-captions; the kernel has no interface for these.
- `\@makecaption`: this is the interface classes and packages are meant to redefine.
- `\@xfloat`, `\@xdblfloat`: wrapped, as in caption.sty.

Tried and rejected: the kernel's generic command hooks `cmd/@xfloat/after` and
`cmd/@xdblfloat/after`. They work in plain documents, but **cannot be added when
babel-french is active** ("can't be retokenized cleanly", because of active characters).
With the float package and floatrow they also failed: 22 more failing tests than with
wrapping. Generic command hooks on kernel internals are therefore no more robust than
wrapping.

Local, temporary redefinitions inside caption contexts remain: `\label`/`\index`/
`\glossary` while measuring, `\stepcounter` in `\caption@@refcounter`, and `\label` in
sub-captions for kernels before 2023-06-01. They are less fragile, but could move to
the label hook and properties later.

## Limitations of this PoC

- **The full test suite only checks that documents compile.** The 14 adaptations that
  were left out without failing tests (wrapfig, sidecap, listings, threeparttable,
  supertabular/xtab, rotating, picins, picinpar, floatflt, fltpage, changepage,
  chkfloat, subfigure, KOMA scrextend, …) would silently change output. A real version
  must keep them; they can be taken over almost unchanged.
- **Tagging is checked on 11 documents.** No validation with veraPDF/PAC (PDF/UA) has
  been done yet.
- **Sub-figures are tagged as `Div`** (latex-lab's minipage tagging). The LaTeX team's
  plan says `Part`; one socket assignment would change this.
- **New float types need `\tagpdfsetup{float/new=<type>}`.** Without it they fail under
  tagging even without caption.
- **`\subref` still uses the `sub@<key>` label.** A properties-based design
  (`\RecordProperties`/`\RefProperty`) was not needed for the results above.

## What the kernel would need

These points are worked out as concrete proposals, with code and tests, in `PROPOSALS.md`.

1. **A hook or socket at the start and end of every float, in the kernel `\@xfloat`.**
   The sockets `float/begin` and `float/end` are already declared in lttagging, but only
   latex-lab's `\@xfloat` uses them. A generic hook would let caption (and others) stop
   wrapping `\@xfloat`.
2. **An interface for captions:** star form, list-entry control, and a sub-caption context.
   The announced template-based captions would be the place for this. caption3 could
   provide the formatting as a template.
3. **latex-lab's `caption/label` socket** ("TODO: revisit after checking float and caption
   packages") could get caption3's label format as a plug.
4. **newfloat (now a separate package) could call `\tagpdfsetup{float/new=…}`** automatically
   for each new float type.

## Remaining work in caption

For a caption release that includes the tagging support:

| Item | Size |
|---|---|
| Put the tagging changes into caption.sty/caption3.dtx (with `\changes`, docs, tests) | S |
| Make sure every adaptation still behaves under tagging (float, floatrow, longtable + latex-lab-table, listings, wrapfig, sidecap, …) | M–L (each adaptation S) |
| Validate with veraPDF / PAC on a test set | M |
| Sub-figure as `Part`, newfloat registration | S |
| Documentation (caption.pdf is outdated, #1) | L |

Most of the first row is done in caption v3.7 (branch `caption-v3.7`).

## What happened next

The tagging changes went into caption itself (v3.7, branch `caption-v3.7`) instead of a
separate caption4 package. The kernel interfaces are worked out in `PROPOSALS.md`.
