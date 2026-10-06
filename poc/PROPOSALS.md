# What caption needs from the kernel: four proposals

**DRAFT, not sent.** 2026-10-04; (c) item 4 changed 2026-10-06 (the hook label is kept). Written against latex2e `develop` at 829e56a15
(format date 2026-11-01, pre-release). caption references are to branch
`fixes-combined` of https://github.com/mark-vis/caption (caption v3.6p, caption3 v2.4e),
other packages and classes as in TeX Live 2026. All files mentioned are in
`poc/proposals/` on branch `poc-caption4` of the same repository.

> **[MARK: About me — placeholder, fill in before sending.]**
> For example: "I am Mark Vis (TU Eindhoven). I fix bugs in the caption bundle in my
> fork (github.com/mark-vis/caption), and I am looking at what caption needs from the
> kernel to work with tagging." Add one sentence on your role, e.g. your arrangement
> with Axel Sommerfeldt.

## Summary

caption changes kernel internals because the kernel has no interface for what it does.
At `\begin{document}` it redefines `\caption` and `\@caption` (star form, list-entry
control, `\ContinuedFloat`, hypcap anchors, sub-captions), wraps `\@xfloat` and
`\@xdblfloat` (to apply `\captionsetup[<type>]` options at the start of every float),
and sets its own `\@makecaption`. Without tagging this works, as long as caption's
definitions are the last ones. With `\DocumentMetadata{tagging=on}` it does not:
latex-lab-float redefines `\caption` and `\@makecaption` and copies `\@xfloat`, so
either caption's settings or latex-lab's tagging are lost (examples in (b)1 and (c)1).
The caption4 proof of concept (`poc/REPORT.md`) showed that caption can be tagged with
the kernel's sockets in about 100 lines, but it still has to redefine the same kernel
commands, and in some places it uses tagpdf internals.

The four proposals below are the interfaces that would let caption (and other packages)
stop doing that. Each one is a small layer on the current code, with tests. The kernel
patches apply to develop one by one and also together (see "Verification of the
combined patch").

| | Proposal | Kernel / latex-lab change | caption side | Size (.dtx lines) | Depends on |
|---|---|---|---|---|---|
| (a) | Hooks at the start and end of every float | ltfloat: mirrored hook pair `float/begin`/`float/end` (2 args), used in `\@xfloat`, `\@xdblfloat`, `\@endfloatbox`; latex-lab-float: the same call in its copy of `\@xfloat` | caption.sty uses the hook instead of wrapping `\@xfloat`/`\@xdblfloat`; a checking wrapper stays for classes that bypass the kernel code | +202/−7 (about 25 lines of code; the rest is `latexrelease` copies and documentation) | — |
| (b) | A caption interface: `\caption*`, list entries, sub-captions | ltfloat: `\caption*`, sockets `caption/step` and `caption/listentry`, `\if@captionstar`; classes: no ": " for an empty label; lttagging: tagging sockets `subfloat/begin`/`subfloat/end`; latex-lab-float: plugs instead of redefining `\caption` | caption plugs `caption/listentry`, prepares `\ContinuedFloat` in `cmd/caption/before`, subcaption uses the sub-float sockets; no more redefinition of `\caption`/`\@caption` | +249/−42 | — |
| (c) | caption3's label format as a plug for `caption/label` | latex-lab-float: documented contract for `caption/label`, new socket `caption/separator`, label tagging sockets usable inside a paragraph, the existing hook label `latex-lab-testphase-float` of latex-lab's `\@makecaption` code documented (not renamed); latex-lab-listings; lttagging documentation | caption3 provides plugs `caption3`; caption.sty keeps its own `\@makecaption` with a `voids` rule against that label and tags the label with the kernel sockets | +102/−17 | (b) |
| (d) | Registering new float types for tagging | lttagging: `\DeclareTaggingFloatType`, the list of float types moves there; latex-lab-float: `float/new` uses it, captions of undeclared types fall back to generic names; latex-lab-namespace: `float/generic/caption`, `float/generic/label` | newfloat (a separate package, see (d)) registers each new type; caption's `\DeclareCaptionType` gets it through newfloat | +97/−23, plus +30 in newfloat | — |

**Recommended order.**

1. The newfloat part of (d) can be done now, without any kernel change: today every
   caption in a float of a new type gives errors under tagging. It is a change for
   newfloat's maintainer, not for the LaTeX team.
2. (a) and the kernel part of (d): small, independent of each other and of (b)/(c).
3. (b): the largest change, and the one with the most open questions (classes,
   template-based captions).
4. (c), on top of (b).

The patch series in `poc/proposals/patches/series/` uses the order (a), (d), (b), (c).

### Release dates and versions

All `\IncludeInRelease` blocks use **2026/11/01**. That is the date develop uses for
its next release: `\fmtversion` is 2026-11-01 (base/ltvers.dtx),
base/TEMPLATE-IncludeInRelease.txt uses 2026/11/01, ltclass.dtx already has blocks with
that date, and base/doc/ltnews44.tex is the draft for November 2026. The team may
prefer a later date; as ltvers.dtx explains, a guessed date is
changed when the release date is fixed. caption's guards do not depend on the date:
(a) tests `\@float@usehooks`, (b) and (c) test whether a socket exists. (d) adds no
`latexrelease` block of its own, because lttagging is one module in `latexrelease`
(`\NewModuleRelease{2024/06/01}{lttagging}`), and the same holds for the sockets (b)
adds there.

In a combined release each file gets one new version: ltfloat v1.2k, lttagging v1.1b,
classes v1.4o, latex-lab-float 0.81q, latex-lab-namespace 0.8s, latex-lab-listings
0.80b, all dated 2026-10-03. In the series, the first patch that touches a file changes
its version line; the stand-alone patches of (a), (b) and (d) each change it themselves.
The `\changes` dates follow each file's own convention (yyyy/mm/dd in base, yyyy-mm-dd
in latex-lab).

### Names used by the proposals

No two proposals define the same name. Some new names sit next to existing ones:

| Name | Kind | Status | Where it runs |
|---|---|---|---|
| `float/begin`, `float/end` | hooks, 2 arguments | new (a) | inside the float box |
| `float/begin`, `float/end` | tagging sockets | existing (lttagging) | latex-lab: outside the float box |
| `subfloat/begin`, `subfloat/end` | tagging sockets, 0 arguments | new (b) | inside the box of a sub-float |
| `caption/begin`, `caption/end` | tagging sockets | existing | around the caption, unchanged |
| `caption/label/begin`, `caption/label/end` | tagging sockets | existing; (c) lets them work inside a paragraph | around the label |
| `caption/step`, `caption/listentry` | sockets | new (b) | `\caption`, `\@caption` |
| `caption/label` | socket (latex-lab) | existing; (c) documents its contract | label text |
| `caption/separator` | socket (latex-lab) | new (c) | after the label |
| `cmd/caption/before` | generic hook | existing; (b) uses it for `\ContinuedFloat` | start of `\caption` |
| `cmd/@makecaption/before` | hook (latex-lab) | existing | start of latex-lab's `\@makecaption` |
| `latex-lab-testphase-float` | label of a `begindocument` hook chunk | existing (the package's default label); (c) documents it and keeps it | latex-lab's redefinition of `\@makecaption` |
| `\DeclareTaggingFloatType` | document-level command | new (d) | preamble |
| `float/<type>/sub`, `float/generic/sub` | structure names (`Part`) | new (b) | sub-floats |
| `float/generic/caption`, `float/generic/label` | structure names | new (d) | captions in floats of undeclared types |
| `\if@captionstar` | legacy boolean | new (b) | during `\caption*` |

The hooks of (a) have the same names as the existing tagging sockets. Hooks and sockets
are separate name spaces, and `para/begin`/`para/end` already exist as both. If this is
confusing, (a) could use `float/box/begin`/`float/box/end` instead (open question (a)1).
(b) deliberately adds no hooks named `caption/before`/`caption/after`, which would be
easy to confuse with `cmd/caption/before` and the tagging socket `caption/begin`.

### How the series differs from the stand-alone patches

The series patches differ from the stand-alone ones in these points:

- (b) added the structure name `float/<type>/sub` to the `float/new` key, whose body (d)
  replaces with `\DeclareTaggingFloatType`. In the series, `\DeclareTaggingFloatType`
  declares `float/<type>/sub` as a fifth name, and latex-lab's `subfloat/begin` plug uses
  (d)'s helper `\__tag_float_name:n{sub}` instead of testing the list of float types, so
  sub-floats fall back to `float/generic/sub` in the same way as captions fall back to
  `float/generic/caption`. The stand-alone (b) patch keeps its own version.
- (c) changes the `caption/label/begin` plug, whose structure line (d) had changed; the
  series keeps (d)'s line.

All patches include the expected updates of existing `.tlg` files, saved with
`l3build save`: four `tlb-latexrelease-rollback-*` tests (new `Applying/Skipping` lines
from (a) and (b), for pdfTeX, LuaTeX and XeTeX), 16 tests of `config-lthooks` (the two
new hooks in hook listings, from (a)) and `float-010-outside` (a tagpdf debug line, from
(d)). In each case the only difference is the added lines, or the two changed debug
lines. The new `float-017-declare` `.tlg` files have `<PDF version="2.0">` like the
other `.tlg` files (see "Verification").

No code had to change because of an interaction between the proposals.

---

## (a) Hooks at the start and end of every float: `float/begin` and `float/end`

Patches: `poc/proposals/patches/standalone/a-float-hooks.patch` (= series 0001).
caption side: `poc/proposals/patches/caption-floathooks.diff` (against caption.sty v3.6p).
Tests: `poc/proposals/tests/tlb-float-hooks-00*`, documents `poc/proposals/mwe/a*.tex`.

### 1. Problem

caption has to run some code at the start of every float, inside the float box, once
`\@captype` is known:

- `\caption@settype{<type>}` applies the options given with `\captionsetup[figure]{...}`,
  resets the caption flags and arranges for pending sub-caption list entries to be
  written at the end of the float;
- `\caption@setanchor` sets the hypcap anchor and resets `\@currentlabel`;
- `\caption@xfloat@hook`, which subcaption and other packages extend;
- for `figure*`/`table*` in two-column mode it also applies the options for `figure*`.

The kernel has no hook for this. `\@xfloat` (base/ltfloat.dtx:376) ends with the box and
nothing after it:

```latex
% base/ltfloat.dtx:470-475
      \normalcolor
      \vbox \bgroup
        \hsize\columnwidth
        \@parboxrestore
        \@floatboxreset
}%
```

and `\@xdblfloat` (ltfloat.dtx:787) only changes the width afterwards:

```latex
\def\@xdblfloat#1[#2]{%
  \@xfloat{#1}[#2]\hsize\textwidth\linewidth\textwidth}
```

So caption replaces both commands at `\begin{document}` (caption.dtx on fixes-combined,
lines 1687-1745):

```latex
  \let\caption@ORI@xfloat\@xfloat
  \let\@xfloat\caption@xfloat
  ...
\def\caption@xfloat#1[#2]{%
  \caption@ORI@xfloat{#1}[#2]%
  \caption@settype{#1}%
  \caption@setanchor
  \caption@xfloat@hook}
\def\caption@xdblfloat#1[#2]{%
  \caption@ORI@xdblfloat{#1}[#2]% expands to \@xfloat{#1}[#2] + extra stuff
  \caption@setoptions{#1*}%
  \caption@xdblfloat@hook}
```

This works, but I would like to get rid of this kind of patch. `\@xfloat` is also
redefined by latex-lab-float (latex-lab-float.dtx:557, a full copy with tagging
sockets), float.sty (float.sty:74-75, for `[H]`), floatrow (floatrow.sty:263-268),
setspace (setspace.sty:418-419) and about a dozen classes. The result depends on load
order, and every wrapper has to repeat the delimited `#1[#2]` syntax.

The alternatives I tried do not work:

- **Generic command hook** `cmd/@xfloat/after`. In a plain document it works
  (`mwe/a1b-cmdhook-nobabel.tex` prints `FLOAT-BEGIN: type=figure, hsize=345.0pt`). With
  babel-french (`mwe/a1-cmdhook-babel.tex`, TeX Live 2026, condensed here) the hook cannot
  be added at all:

  ```latex
  \documentclass{article}
  \usepackage[T1]{fontenc}
  \usepackage[french]{babel}
  \makeatletter
  \AddToHookWithArguments{cmd/@xfloat/after}{%
    \typeout{FLOAT-BEGIN: type=\@captype, hsize=\the\hsize}}
  \makeatother
  \begin{document}
  \begin{figure}[ht] \centering X \caption{Une figure} \end{figure}
  \end{document}
  ```

  ```
  ! LaTeX hooks Error: Generic hooks cannot be added to '\@xfloat'.
  You tried to add a hook to '\@xfloat', but LaTeX was unable to patch the
  command because it can't be retokenized cleanly.
  ```

  The hook code never runs, so caption's type options would be lost silently. In the
  caption4 PoC, the cmd-hook version also gave 22 more failing documents with float.sty
  and floatrow than wrapping did.
- **Environment hooks** (`env/figure/begin`, `env/figure/after`, ...). They run outside
  the float box: `env/<name>/begin` runs before `\@xfloat` has set `\@captype` and
  opened the box (ltfloat.dtx:376-475), and `env/<name>/after` runs after the box has
  been closed. They also exist per environment name, not per float type, so caption
  would have to add code for every float environment that any package defines,
  including `figure*` and environments like `sidewaysfigure` that call `\@float`
  themselves.
- **`\@floatboxreset`** is redefined by many classes (amsart, amsbook, amsproc, llncs,
  mwart/mwbk/mwrep, lni, IEEEtran even per environment) and by float.sty, so code
  appended there gets lost.
- **The tagging sockets** `float/begin` and `float/end` (lttagging.dtx:973-974). In
  `\@xfloat`/`\end@float` latex-lab uses them outside the float box
  (latex-lab-float.dtx:622, 640, 662), and the `float/split` key uses them inside the
  float body to close and reopen the float structure (latex-lab-float.dtx:419-430). As far
  as I understand, they are meant for the tagging code, with one plug at a time, and not
  for package code.

### 2. Proposed interface

A mirrored pair of kernel hooks with two arguments each, declared with
`\NewMirroredHookPairWithArguments{float/begin}{float/end}{2}`. Like
`para/begin`/`para/end` (`\hook_new_pair:nn`, ltpara.dtx:692), code added to `float/end`
runs in reverse order, so code from two packages nests properly.

| hook | #1 | #2 |
|---|---|---|
| `float/begin` | float type (`figure`, `table`, the argument of `\@float`) | `*` for a double-column float in two-column mode, empty otherwise |
| `float/end` | same | same |

**Where `float/begin` runs.** As the last thing in `\@xfloat`: inside the float box and
inside the environment group, after `\@captype` and `\@fps` are set, `\@currbox` is
allocated, and `\@parboxrestore` and `\@floatboxreset` have run (font reset,
`\@minipagetrue`). For a double-column float in two-column mode, `\@xdblfloat` runs it
instead, after `\hsize` and `\linewidth` are set to `\textwidth`. In that case the hook
runs once, with `#2` = `*`. In one-column mode `figure*` is `\@float`, so `#2` is empty.
That is the same case distinction caption makes today.

**Where `float/end` runs.** In `\@endfloatbox`, after the final `\par` and before
`\vskip\z@skip` and the end of the box. This covers `\end@float` and `\end@dblfloat`,
and also packages that end the float box themselves (float.sty's `\float@end`,
multicol's `\end@dblfloat`). `float/end` runs only in the `\@endfloatbox` that closes the
box in which `float/begin` ran. `\@float@usehooks` records `\currentgrouplevel` and
defines `\@float@end@hook` locally. `\@float@end@hook` is `\relax` outside floats, and
inside a float it does nothing at any other group level. This matters because packages
use `\@endfloatbox` for boxes that did not start with `\@xfloat`, and such a box can sit
inside a float: for example a float.sty `[H]` float in a minipage in a `figure`. The
first version of this patch ran `float/end` twice there, once with the arguments of the
outer figure. Test 5 of `tlb-float-hooks-001` covers this case, and
`mwe/a4-nested-H.tex` covers it with the real float.sty.

**Order with tagging** (latex-lab-float): socket `float/begin` (structure opened,
outside the box), then the box, then `\MakeLinkTarget*{<type>.struct.<n>}`, then **hook
`float/begin`**, then the float body, then **hook `float/end`**, then the box ends, then
socket `float/end`. Hook code is therefore inside the float structure and after the
float's link target. `float/split` happens in the body and does not touch the hooks.

**Naming.** See "Names used by the proposals" above; `float/box/begin` would also do.

**Not covered** (and not meant to be): float.sty `[H]` (`\@float@HH` does not use
`\@xfloat`), wrapfig, `\captionof` in a minipage, longtable. These are not `\@xfloat`
floats. caption keeps `\setcaptiontype` and its package adaptations for them. rotating's
`sidewaysfigure` uses `\@float` and gets the hooks. float.sty, floatrow and setspace wrap
`\@xfloat` and call the kernel version, so they get the hooks too. floatrow sets
`\let\@xdblfloat\@xfloat` for its own double floats, so `#2` is empty there.

Packages that replace the macros without the new calls do not get the hooks, or get them
in a different form:

- classes that replace `\@xfloat` completely without calling the kernel version
  (revtex, aastex, seminar, ...): no hooks at all;
- nidanfloat.sty:49-52 redefines `\@xdblfloat` as the old one-liner: `float/begin` then
  runs inside `\@xfloat` with `#2` empty and `\hsize` = `\columnwidth`;
- acmart in sigchi-a mode (acmart.cls:963-982) uses its own `\@endwidefloatbox` for wide
  floats: `float/begin` runs there, `float/end` does not;
- ftnxtra and bidiftnxtra also define `\@endfloatbox` (not checked further).

caption checks for the first two cases (section 5).

**Backward compatibility.** Both hooks are empty by default, so no output changes. The
new definitions are in `latexrelease` blocks dated 2026/11/01 (see "Release dates and
versions"). On rollback the hooks stay declared but are not executed (test
`tlb-float-hooks-002-rollback`). The rollback block defines the three helper macros as
`\@gobbletwo`, `\@gobble` and `\relax` instead of undefining them, so code that still
calls them after a rollback (latex-lab's copy of `\@xfloat`, if it were loaded after the
rollback) keeps working.

### 3. Code sketch against latex2e develop

The full patch (base/ltfloat.dtx, required/latex-lab/latex-lab-float.dtx, changes.txt,
two new tests, updated `.tlg` files) is `patches/standalone/a-float-hooks.patch`. The
new code in ltfloat.dtx, without documentation and `latexrelease` copies:

```latex
\NewMirroredHookPairWithArguments{float/begin}{float/end}{2}
\def\@float@usehooks#1#2{%
  \edef\@float@hook@level{\the\currentgrouplevel}%
  \def\@float@end@hook{%
    \ifnum\currentgrouplevel=\@float@hook@level\relax
      \expandafter\@firstofone
    \else
      \expandafter\@gobble
    \fi
    {\UseHookWithArguments{float/end}{2}{#1}{#2}}}%
  \UseHookWithArguments{float/begin}{2}{#1}{#2}}
\def\@float@begin@hook#1{\@float@usehooks{#1}{}}
\let\@float@end@hook\relax
```

and the three call sites:

```latex
% end of \@xfloat (and of latex-lab's copy, after \MakeLinkTarget*):
        \@float@begin@hook{#1}%
% \@endfloatbox:
      \par
      \@float@end@hook
      \vskip\z@skip
% \@xdblfloat:
\def\@xdblfloat#1[#2]{%
  \let\@float@begin@hook\@gobble
  \@xfloat{#1}[#2]\hsize\textwidth\linewidth\textwidth
  \@float@usehooks{#1}{*}}
```

### 4. Verification

These runs were made on the single patch (results for the combined
patch are in the last section).

- **New test** `tlb-float-hooks-001.lvt` (saved with `l3build save`, pdfTeX; LuaTeX
  gives the same `.tlg`). It prints the hook arguments and the state at the hook.
  Excerpt of the `.tlg`:

  ```
  TEST 1: one-column figure
  BEGIN: figure [], captype=figure, hsize=400.0pt, linewidth=400.0pt, mode=inner vertical, minipage
  END: figure [], captype=figure, hsize=400.0pt, mode=inner vertical
  TEST 4: a box ended by @endfloatbox without @xfloat: no hook
  box done
  TEST 5: a box ended by @endfloatbox nested in a float (like float.sty [H] in a minipage): end hook only once, for the float
  BEGIN: figure [], captype=figure, ...
  END: figure [], captype=figure, hsize=400.0pt, mode=inner vertical
  TEST 6: two-column figure
  BEGIN: figure [], captype=figure, hsize=190.0pt, linewidth=190.0pt, ...
  TEST 7: two-column figure*
  BEGIN: figure [*], captype=figure, hsize=400.0pt, linewidth=400.0pt, ...
  END: figure [*], captype=figure, hsize=400.0pt, mode=inner vertical
  TEST 9: code from two labels: float/end is reversed
  pkgA begin: figure
  pkgB begin: figure
  BEGIN: figure [], ...
  END: figure [], ...
  pkgB end: figure
  pkgA end: figure
  ```

  `tlb-float-hooks-002-rollback.lvt` (`latexrelease` 2026-06-01): the hooks are declared
  but no output appears. Both pass with `l3build check -e pdftex` and `-e luatex`.
- **Nested `[H]` with the real float.sty** (`mwe/a4-nested-H.tex`): a `program` `[H]` float in a minipage in a `figure`. With the first version
  of the patch it printed `END figure [] captype=program` and then
  `END figure [] captype=figure`. Now it prints one `BEGIN figure []` and one
  `END figure [] captype=figure`, with 0 errors.
- **Existing base tests.** On the first version of the patch, `l3build check -e pdftex`
  on 44 tests chosen because they exercise floats, float placement/tracing, two-column
  floats and rollback: `tlb-fltrace-000…005b`, `tlb-fltrace-*-2015`,
  `tlb-fltrace-rollback-2024-11-01`, `tlb-flafter-rollback-2024-11-01`, `tlb-hfloat-01`,
  `tlb-negfloat-001…003`, `tlb0002a…d`, `tlb0084(-2015)`, `github-0094`, `github-0580`,
  `tlb-latexrelease-rollback-*`, `tlb-rollback-001…003`, and more. All passed except the
  rollback tests whose diffs contain only the new `Applying/Skipping: [....-..-..] Float
  hooks` lines; their `.tlg` files are now updated in the patch.
- **`config-lthooks`** (pdfTeX, 99 tests): 16 tests change (`ltcmdhooks-001`,
  `lthooks-000`…`009`, `-011`, `-013`, `-021`, `lthooks-legacy`,
  `lthooks-rollback-args`), only by added lines: the two new hooks in hook listings
  (`[lthooks] Update code for hook 'float/begin'`, `> {float/begin}`, the same for
  `float/end`) and the `Float hooks` release lines. The updated `.tlg` files are in the
  patch.
- **latex-lab** `l3build check -c config-float` (all float and marginpar tests, pdfTeX
  and LuaTeX, including the PDF-based `.pvt` tests): same result as the unpatched copy.
- **Rollback under tagging** (`mwe/a6-rollback-tagging.tex`): `\DocumentMetadata{tagging=on}`
  followed by `\RequirePackage[2026-06-01]{latexrelease}`. The rollback restores the
  kernel `\@xfloat` over latex-lab's copy, so the hook macros are not called. The run
  gives the same single error as the unpatched develop format (`Package tagpdf Error:
  there is no open structure on the stack`). So I could not trigger the undefined-macro
  case; the `\@gobble` stubs are there for safety. Without the rollback (`mwe/a6x.tex`)
  there are 0 errors and the hook runs.
- **User documents** (`mwe/a2-caption-user.tex`: two-column article, babel-french,
  hyperref, `\captionsetup[figure]`, `[figure*]`, `[table]`; `mwe/a3-caption-user-tagging.tex`:
  the same under `\DocumentMetadata{tagging=on}`). Stock caption against caption with the
  hook (section 5) on the patched format: identical text (`pdftotext -layout`), `.aux` and,
  for a3, structure tree (`Figure 1. Une figure`, `Figure 2 – Une figure large`,
  `Table 1 Un tableau`, same anchors). With the hook, `\@xfloat` and `\@xdblfloat` keep
  the kernel definitions.
- **caption's guard and fallback** (`mwe/a5-*.tex`, two-column, `figure` and `figure*`).
  Each float calls `\caption@settype` exactly once, and each `figure*` sets the `figure*`
  options exactly once, with the same text as stock caption:
  - plain article: neither macro is wrapped;
  - setspace and float.sty (also with `[H]`): `\@xfloat` is wrapped with the checking
    wrapper, the hook does the work;
  - an nidanfloat-style `\@xdblfloat`: only `\@xdblfloat` is wrapped;
  - a class copy of `\@xfloat` without the hook (simulated with `\patchcmd`): the wrapper
    does the work;
  - `latexrelease` 2026-06-01: old wrapping.
- **caption test suite**: all 132 documents of caption's `test/` (except `fallback/`) on
  the patched format, stock caption against caption with the hook. Error counts and text
  are identical for all documents. 35 documents have errors in both runs: many because
  the l3build format has no hyphenation patterns for babel languages, plus the known
  floatrow/longtable ones. This includes the floatrow and float.sty documents where the
  cmd-hook version failed. (Not rerun on the combined patch.)
- The documentation of the patched `ltfloat.dtx` typesets without errors.

**Not verified:** the full `l3build check` of base and latex-lab; XeTeX; real classes
that replace `\@xfloat` completely (revtex, aastex; only simulated); nidanfloat itself
(it is for pLaTeX; only simulated) and acmart sigchi-a; a `latexrelease` roll-forward
from an older format.

### 5. How caption would use it

In `caption.sty`, `\caption@redefine` (run at `\begin{document}`) uses the hook when the
kernel has it and it is not disabled by a rollback. Otherwise it wraps as before
(`patches/caption-floathooks.diff`, against caption v3.6p):

```latex
\newcommand*\caption@redefine{%
  \let\caption\caption@caption
  \let\@caption\caption@@caption
  \caption@iffloathooks
    {\caption@floathooks}%
    {\let\caption@ORI@xfloat\@xfloat
     \let\@xfloat\caption@xfloat
     \let\caption@ORI@xdblfloat\@xdblfloat
     \let\@xdblfloat\caption@xdblfloat}%
}
\newcommand*\caption@iffloathooks{%
  \@tempswafalse
  \ifdefined\@float@usehooks
    \ifx\@float@usehooks\@gobbletwo\else\@tempswatrue\fi
  \fi
  \if@tempswa\expandafter\@firstoftwo\else\expandafter\@secondoftwo\fi}
\newcommand*\caption@ifinmeaning[2]{% is #1 in the meaning of #2?
  \edef\caption@tempa{\noexpand\in@{\string#1}{\meaning#2}}%
  \caption@tempa
  \ifin@\expandafter\@firstoftwo\else\expandafter\@secondoftwo\fi}
\newcommand*\caption@floathooks{%
  \AddToHookWithArguments{float/begin}[caption]{%
    \let\caption@float@hooked\@empty
    \caption@settype{##1}%
    \caption@setanchor
    \caption@xfloat@hook
    \ifx\relax##2\relax \else
      \let\caption@dblfloat@hooked\@empty
      \caption@setoptions{##1##2}%
      \caption@xdblfloat@hook
    \fi}%
  \caption@ifinmeaning\@float@begin@hook\@xfloat{}{%
    \let\caption@ORI@xfloat\@xfloat
    \let\@xfloat\caption@xfloat@check}%
  \caption@ifinmeaning\@float@usehooks\@xdblfloat{}{%
    \let\caption@ORI@xdblfloat\@xdblfloat
    \let\@xdblfloat\caption@xdblfloat@check}}
\def\caption@xfloat@check#1[#2]{%
  \caption@ORI@xfloat{#1}[#2]%
  \ifx\caption@float@hooked\@empty \else
    \ifx\@float@begin@hook\@gobble \else % kernel \@xdblfloat runs the hook later
      \caption@settype{#1}%
      \caption@setanchor
      \caption@xfloat@hook
    \fi
  \fi}
\def\caption@xdblfloat@check#1[#2]{%
  \caption@ORI@xdblfloat{#1}[#2]%
  \ifx\caption@dblfloat@hooked\@empty \else
    \caption@setoptions{#1*}%
    \caption@xdblfloat@hook
  \fi}
```

The guard tests `\@float@usehooks` rather than the format date: a development format
and a release with the same date cannot be told apart, and after a `latexrelease`
rollback the macro is `\@gobbletwo`.

The meaning test only looks one level deep. When `\@xfloat` is a wrapper that calls the
kernel version (float.sty, floatrow, setspace), caption cannot see the hook. It then
still wraps `\@xfloat`, but the wrapper only does the work if the hook did not run for
this float (the local flag `\caption@float@hooked`). So nothing runs twice, and a class
with its own complete `\@xfloat` still gets caption's settings. The same holds for an
`\@xdblfloat` without `\@float@usehooks` (nidanfloat). In the plain case (kernel or
latex-lab `\@xfloat`), caption no longer touches `\@xfloat` or `\@xdblfloat`. With a
public way to test for the hooks, caption would use that instead of the internal names.

The `float/end` hook is not needed by caption today. It would be the place for flushing
pending sub-caption list entries (now `\aftergroup\flushsubcaptionlistentries`); see the
list-entry socket in (b), whose client sketch keeps sub-entries back until the main
entry is written.

### Open questions for the team

1. Are the names fine next to the sockets of the same name, or do you prefer something
   like `float/box/begin`?
2. Is `*` as the second argument a good way to pass "double-column float", or would you
   rather have a separate `dblfloat/begin` hook, or a public flag?
3. Should `float/begin` also run for float.sty `[H]` floats? latex-lab-firstaid already
   redefines `\@float@HH` under tagging (latex-lab-firstaid.dtx:1480). For untagged
   documents, latex2e-first-aid would need to do the same. (See also (d), question 6.)
4. Would you add a public test for "the float hooks are active", so packages do not have
   to test internal macros? (The same question comes up in (d), question 4.)
5. Would a separate hook outside and before the float box (where latex-lab calls
   `\@@_float_init:` and the `float/begin` socket, latex-lab-float.dtx:621-622) be useful
   as well? caption does not need one, but the TODO at latex-lab-float.dtx:246-250 asks
   whether `\@@_float_init:` should become a hook.

---

## (b) A caption interface: `\caption*`, list entries, sub-captions

Patches: `poc/proposals/patches/standalone/b-caption-interface.patch` (stand-alone) and
series 0003 (on top of (a) and (d)). Tests: `poc/proposals/tests/caption-interface-001.*`,
`poc/proposals/tests/float-020-caption-interface.*`. Client sketches:
`poc/proposals/mwe/captionclient.sty`, `mwe/caption-excerpt.tex`.

### 1. Problem

The kernel `\caption` and `\@caption` (base/ltfloat.dtx:240-249 and 259-292) have no
entry points. `\refstepcounter\@captype` and
`\addcontentsline{\csname ext@#1\endcsname}...` are hard-coded, and there is no star
form. So every package that needs a slightly different caption redefines both commands,
and the last definition wins:

- **caption.sty** redefines `\caption` and `\@caption` at `\begin{document}`
  (caption.dtx:1670-1706), together with the `\@xfloat` wrapping of (a). The comment
  there says why: "Some packages (like the hyperref package for example) redefines
  \caption and \@caption, too. So we have to use \AtBeginDocument here, so we can make
  sure our definition is the one which will be valid at last." Its own versions
  (`\caption@caption`, caption.dtx:1508, and `\caption@@caption`, :1553) add:
  - `\caption*`;
  - list-entry control: `\caption[]{...}` gives no entry, and there are `list=false`,
    `\captionlistentry`, and sub-entries written after the main entry. All of this lives
    in caption3's `\caption@addcontentsline` (caption3.dtx:3894);
  - `\ContinuedFloat` (the counter is not stepped, caption.dtx:2484-2505);
  - hypcap anchors;
  - sub-captions (subcaption replaces `\caption` locally inside `subfigure`).
- **latex-lab-float** redefines `\caption` when it is loaded (latex-lab-float.dtx:777-801).
  It does this only to change the counter step: `\@kernel@refstepcounter\@captype` plus
  `\xdef\@currentHref{\@captype.struct.\@current@float@struct}`. It also replaces
  `\@makecaption` at `begindocument` (:809-850; that is the subject of (c)).
- **hyperref** without `\DocumentMetadata` redefines `\caption` and `\@caption` for its
  anchors (hyperref.sty:7281-7343). With `\DocumentMetadata` it does not
  (`\hyper@nopatch@caption`, hyperref.sty:109-121).

Compiled with TL 2026:

- `mwe/b-kernel.tex` (kernel only): `\caption*{Unnumbered caption}` prints
  "Figure 1: \*" and then the text as a normal paragraph, and the LoF gets the entry
  "1 \*". `\caption[]{...}` writes an empty LoF line (`\numberline {2}{\ignorespaces }`).
- `mwe/b-tagging.tex` (caption 3.6 + subcaption + hyperref, `\DocumentMetadata{tagging=on}`):
  - At `\begin{document}`, `\caption` and `\@caption` are caption's, but `\@makecaption`
    is latex-lab's.
  - latex-lab's counter/target code is gone, so tagpdf warns "Destination
    'figure.caption.2' has no related structure" (tagging-project #85).
  - `\caption*{Unnumbered}` prints "Figure 1: Unnumbered", because latex-lab's
    `\@makecaption` does not know caption's star flag.
  - `labelsep=period` and `labelfont=bf` are lost.

Sub-figures have no kernel support at all: "Subfigures and subcaptions are currently not
handled, but will be implemented as simple `Part` with their own `Caption`"
(latex-lab-float.dtx:99-100).

The long-term plan is template-based captions. ltnews43.tex:346-357 says the new context
mechanism "is going to be used when we implement caption handling using the template
mechanism", and latex-lab-context.dtx:673-679 has TODOs for it. ltnews43.tex:449-464
shows a possible signature, `\DeclareDocumentCommand\caption{s ={short-title} +O{#3} +m}`.
It explains that a given but blank `[]` becomes an empty keyval list, and "For cases
where a classical `[]` means something is explicitly empty, adding an empty brace group
(`[{}]`) will work". caption has always documented `\caption[]{...}` as "no list entry".
Under that signature, `[]` would no longer mean that; users would have to write `[{}]`.

### 2. Proposed interface

This is a small layer on top of the current code. Each package gets one place to plug
in, and nobody has to redefine `\caption` or `\@caption` any more. New:

| Name | Kind, arguments | Where it is used | Default | Expected plug owner |
|---|---|---|---|---|
| `\caption*` | kernel star form | `\caption` | no counter step, no target, no list entry; `\@makecaption{}{text}` | — |
| `\if@captionstar` | legacy boolean | true from `\caption*` until the end of `\@caption` | false | read by `\@makecaption` |
| `caption/listentry` | socket, 2 args (type, list text) | `\@caption`, before the group, not for `\caption*` | plug `kernel` = today's `\addcontentsline` | caption |
| `caption/step` | socket, 1 arg (counter) | `\caption`, not for `\caption*` | plug `kernel` = `\refstepcounter{#1}` | latex-lab only |
| `subfloat/begin`, `subfloat/end` | tagging sockets, 0 args | used by sub-float packages (subcaption) | latex-lab: structure `float/<type>/sub` (role `Part`) | latex-lab only |

Existing points that the proposal relies on and does not change:

- the generic hook `cmd/caption/before`, which runs before the counter step (caption
  prepares `\ContinuedFloat` there);
- the hook `cmd/@makecaption/before`{2} (latex-lab-float.dtx:809), for formatting code;
- the sockets `refstepcounter` and `refstepcounter/target` (ltxref.dtx:469, 482).

Details:

- `\caption*[x]{text}`: the optional argument is accepted and ignored.
- `\@makecaption` gets an empty first argument for `\caption*`. The standard classes
  (classes.dtx) then drop the ": " (`\if\relax\detokenize{#1}\relax`). latex-lab's
  `\@makecaption` tests `\if@captionstar` and makes the label sockets `noop`, as
  latex-lab-listings already does for listing titles (latex-lab-listings.dtx:203-209).
  With (c), it also makes `caption/separator` `noop`.
- `caption/listentry` gets the optional argument exactly as given. The kernel plug still
  writes an empty entry for `[]` (no change); caption's plug writes none.
- `caption/step` replaces latex-lab's redefinition of `\caption`. latex-lab's plug sets
  the float target, except outside a float and inside a sub-float. There it runs the code
  (plain `\refstepcounter`), as today outside floats. A sub-caption steps its own counter
  with `\refstepcounter{sub<type>}` and does not use the socket.
- The sub-float sockets give the structure `Part` > (`Caption`, content). `caption/begin`
  already takes the parent structure number (lttagging.dtx:979-989), so a sub-caption
  becomes the first kid of its `Part` without any other change. The structure names are
  per type, like the other float names: `float/figure/sub`, `float/table/sub` and
  `float/generic/sub` in latex-lab-namespace, and `float/<type>/sub` for new types. In the
  stand-alone patch `float/new` declares it (latex-lab-float.dtx:286-292); together with
  (d), `\DeclareTaggingFloatType` declares it, and types that are not declared use
  `float/generic/sub`.
- `\@xfloat`/`\end@float` and the tagging sockets `float/begin`/`float/end` are not
  changed (the float begin hook is proposal (a)).

**Why not the existing interfaces?**

- *`refstepcounter` / `refstepcounter/target`.* `refstepcounter` wraps every
  `\refstepcounter`. hyperref owns it (plugs `hyperref` and `hyperref/fixcleveref`,
  hyperref.sty:6634-6645) and also owns `refstepcounter/target` (:6648-6665). latex-lab
  needs a different target only for the one step in `\caption`. It would have to assign
  its own plug just before that step, put hyperref's plug back afterwards, and pass every
  other counter on to hyperref. That needs a hook around the step anyway, plus knowledge
  of which plug to restore. A socket at the step itself is smaller. It has to be a normal
  socket, not a tagging socket, because latex-lab also uses the float target when
  tagging is not active. I tried a tagging socket first, and the existing test
  `float-tagging-off` failed: the target became `figure.1` instead of `figure.struct.1`.
- *`cmd/@makecaption/before`.* An earlier version of this draft added hooks
  `caption/before` and `caption/after` around `\@makecaption`. They are not needed:
  formatting code can use `cmd/@makecaption/before`, which asmeconf.cls, asmejour.cls,
  mitthesis.cls and biblatex-apa already use. latex-lab can handle the star case in its
  own `\@makecaption`. caption keeps its own `\@makecaption`, so it does its type options
  there.
- *`cmd/caption/before`.* It runs at the start of `\caption`, before the step. That is
  exactly where caption has to prepare a continued float. So caption does not need to
  own a step socket.

**Who owns which socket.** A socket has one plug, so a socket that several packages want
to change only moves the "last definition wins" problem into the socket. The earlier
draft had that problem: latex-lab, caption and (classic) hyperref would all have wanted
the plug of a `caption/step` socket, and caption had to chain the previous plug. The
design here avoids it:

- `caption/step` belongs to the float code of the tagging project (latex-lab). caption
  does not plug it.
- `caption/listentry` is for a package that takes over list entries (in practice
  caption).
- `\ContinuedFloat` uses a hook, and hooks can have many users.

What is left is caption's own technique for continued floats: a local, self-removing
redefinition of `\stepcounter` (as in caption.dtx:2493-2505). A documented "do not step
this caption" flag in the kernel would be cleaner (see the open questions).

**Backward compatibility.**

- Documents that do not use `\caption*` produce the same output. The `latexrelease`
  blocks restore the old `\caption`/`\@caption`. The new sockets and `\if@captionstar`
  are also declared, guarded, in the `latexrelease` part, so rolling forward works too.
- `\caption*` itself is a visible change. Today the kernel prints "Figure 1: \*" and the
  text. With the patch:
  - the standard classes print just the text;
  - classes that have their own `\@makecaption` or wrap the kernel `\caption` inherit the
    new `\caption*`. The counter and the LoF are right, but they print the separator in
    front of the text: memoir (memoir.cls:5953-5962 wraps `\caption`/`\@caption`) and
    KOMA (scrartcl.cls:5710, own `\@makecaption`) give ": Starred", and amsart
    (amsart.cls:1386) gives ". Starred". These classes would have to test
    `\if@captionstar` or an empty first argument.
- Packages that redefine `\caption`/`\@caption` (caption today, hyperref without
  `\DocumentMetadata`) bypass the new points, as they do now. Nothing breaks, but they
  gain nothing until they become clients. In my test, a document *without*
  `\DocumentMetadata` but with hyperref ignores the interface completely.

**How this maps onto template-based captions.** The new points are meant as the inside
of a later template-based `\caption`, so that clients keep working when it arrives:

- `caption/listentry` would be the list-entry step of the template;
- `\if@captionstar` would be a key such as `label=false`;
- `caption/step` would be the counter step of the instance;
- the sub-float sockets would stay as they are.

### 3. Code sketch against latex2e develop

The full patch also changes classes.dtx (`\@makecaption` without ": " for an empty
label), lttagging.dtx (declaration and documentation of `subfloat/begin|end`),
latex-lab-namespace.dtx (`float/figure/sub`, `float/table/sub`, `float/generic/sub`) and
`changes.txt`, and adds the two tests. The core, in ltfloat.dtx (declarations guarded so
that `latexrelease` can roll forward):

```latex
\IfSocketExistsF{caption/step}{%
  \NewSocket{caption/step}{1}%
  \NewSocketPlug{caption/step}{kernel}{\refstepcounter{#1}}%
  \AssignSocketPlug{caption/step}{kernel}%
}
\IfSocketExistsF{caption/listentry}{%
  \NewSocket{caption/listentry}{2}%
  \NewSocketPlug{caption/listentry}{kernel}
    {%
      \addcontentsline{\csname ext@#1\endcsname}{#1}%
        {\protect\numberline{\csname the#1\endcsname}{\ignorespaces #2}}%
    }%
  \AssignSocketPlug{caption/listentry}{kernel}%
}
\@ifundefined{if@captionstar}{\newif\if@captionstar}{}

\def\caption{%
   \ifx\@captype\@undefined
     \@latex@error{\noexpand\caption outside float}\@ehd
     \expandafter\@gobble
   \else
     \expandafter\@firstofone
   \fi
   {\@ifstar
      {\@captionstartrue\@dblarg{\@caption\@captype}}%
      {\@captionstarfalse
       \UseSocket{caption/step}{\@captype}%
       \@dblarg{\@caption\@captype}}}%
}
\long\def\@caption#1[#2]#3{%
  \par
  \if@captionstar \else
    \UseSocket{caption/listentry}{#1}{#2}%
  \fi
  \begingroup
    \@parboxrestore
    \if@minipage
      \@setminipage
    \fi
    \normalsize
    \if@captionstar
      \expandafter\@firstoftwo
    \else
      \expandafter\@secondoftwo
    \fi
    {\@makecaption{}}%
    {\@makecaption{\csname fnum@#1\endcsname}}%
      {\ignorespaces #3}\par
  \endgroup
  \@captionstarfalse}
```

In latex-lab-float, the redefinition of `\caption` is replaced by a plug, and the
sub-float sockets get plugs (series version; the stand-alone version tests the list of
float types instead of using (d)'s `\__tag_float_name:n`):

```latex
\bool_new:N \l_@@_subfloat_bool
\NewSocketPlug{caption/step}{latex-lab}
  {
    \bool_lazy_or:nnTF
      { \tl_if_empty_p:N \@current@float@struct }
      { \l_@@_subfloat_bool }
      { \refstepcounter {#1} }
      {
        \@kernel@refstepcounter {#1}
        \xdef\@currentHref{\@captype.struct.\@current@float@struct}
      }
  }
\AssignSocketPlug{caption/step}{latex-lab}
\NewTaggingSocketPlug{subfloat/begin}{default}
  {
    \tag_struct_begin:n{tag=\UseStructureName{\@@_float_name:n{sub}}}
    \tl_set:Ne\@current@float@struct{\tag_get:n{struct_num}}
    \bool_set_true:N \l_@@_subfloat_bool
  }
\AssignTaggingSocketPlug{subfloat/begin}{default}
\NewTaggingSocketPlug{subfloat/end}{default}
  { \tag_struct_end: }
\AssignTaggingSocketPlug{subfloat/end}{default}
```

and its `\@makecaption` makes the label sockets `noop` when `\if@captionstar` is true.

### 4. Verification

These runs were made on the stand-alone patch (results for the
combined patch are in the last section).

- **base, pdfTeX**: `l3build check -e pdftex caption-interface-001 tlb-hfloat-01
  tlb0018 tlb1893 tlb2400 tlb2815 github-robust-0123 tl2e8 tltx001 tltc001`. All pass.
  These are the base tests that use `\caption` (found with grep); tlb2815 is the
  "\caption outside float" error. The unpatched clone also passes them.
- **New base test** `caption-interface-001.lvt`. I made the `.tlg` with `l3build save`
  and read it by hand. It covers:
  - a normal caption (`\@makecaption` gets `\csname fnum@\@captype\endcsname`);
  - `\caption*` and `\caption*[x]`: no step, no `\addcontentsline`, an empty first
    argument, and the star flag is reset afterwards;
  - `\caption[]` with the kernel plug (an empty entry, as before) and with a test plug
    (no entry);
  - a continued float prepared in `cmd/caption/before`: the number stays 4, and the next
    figure is 5;
  - article's `\@makecaption` with an empty label: `\showbox` contains only "Text", with
    no ": ";
  - `\caption` and `\caption*` outside a float: the same error as before.
- **latex-lab**, `l3build check -c config-float` (pdfTeX + LuaTeX): only
  `firstaid-float-H-2` and the new `float-020` differ, and only in the line
  `<PDF version="2.0">` vs `<PDF>` (see "Verification of the combined patch"). It is the
  same on the unpatched clone. The other latex-lab tests that use captions
  (`config-block firstaid-listings`, `config-table-pdftex|luatex table-012-caption
  table-013-longtable-hyperref (table-021-longtable)`, `tlb-context-001`) give the same
  results as on the unpatched clone. The test `float-tagging-off` matters here: it caught
  my first attempt, which used a tagging socket for the step (see section 2).
- **New latex-lab test** `float-020-caption-interface.lvt` (pdfTeX and LuaTeX `.tlg`),
  with hyperref and tagging:
  - a normal caption: target `figure.struct.5`, `Caption` > `Lbl "Figure 1:"`, `P`;
  - `\caption*`: the counter stays 1, and `Caption` has only `P`;
  - a sub-float with a numbered sub-caption: target `subfigure.1.1` (hyperref's own),
    `Part` > (`Caption` > `Lbl "(a):"`, `P`), then the content; `\ref` to it works;
  - a sub-float with `\caption*`: `Part` > `Caption` > `P`;
  - the main caption after the sub-floats: target `figure.struct.12`, first kid of the
    float.
- **Client document** (`mwe/client-doc.tex` with `mwe/captionclient.sty`, pdfLaTeX and
  LuaLaTeX, in three variants: tagging + hyperref, no tagging and no hyperref, and no
  tagging with classic hyperref). 0 errors in all six runs.
  - `\caption*`: no number, no LoF entry.
  - `\caption[]`: numbered, no entry.
  - The sub-entries "a Sub A" and "b Sub B" are written *after* their main entry (level
    2), even though the sub-captions come first. Each one keeps its own link target
    (`subfigure.1`, `subfigure.2`), not the main float's.
  - `\ContinuedFloat` keeps the number (3, 3).
  - `\ref` to the sub-figure works.
  - With tagging there is no "has no related structure" warning. The main `Caption` is
    the first kid of the float, and each sub-caption is the first kid of its `Part`. The
    only tagging warning is "Parent-Child 'Link' --> 'Link'", which comes from a `\ref`
    inside a caption that is also linked from the LoF; caption.sty gives it too.
  - With classic hyperref (no `\DocumentMetadata`), hyperref's own `\caption` replaces
    the kernel's, and the interface is bypassed: `\caption*` gives a LoF entry "\*" and
    `[]` an empty one. This is as described under backward compatibility.
- **Section 5 excerpt**: `mwe/caption-excerpt.tex` is exactly the code shown in section 5.
  `mwe/caption-excerpt-doc.tex` loads it with stubs for the caption internals it calls.
  With the patched format: 0 errors, the new path, `[]` gives no entry, the continued
  figure keeps number 2, and the sub-caption is stepped and listed. With TL 2026: 0
  errors, and the old path is taken.
- **Other classes** (`mwe/cls-star.tex`, patched format, pdfLaTeX): article, report:
  "Starred"; memoir, scrartcl: ": Starred"; amsart: ". Starred". In every case there is no
  LoF entry, and the next figure has the right number (memoir 0.2, the others 2). This
  is the class issue described in section 2.
- **latexrelease**:
  - Rollback (`mwe/release-back.tex`): the patched format with
    `\RequirePackage[2026-06-01]{latexrelease}` gives the old behaviour (`\caption*`
    prints "Figure 2: \*", with a LoF entry "\*").
  - Roll-forward (`mwe/release-fwd.tex`): the TL 2026 format (2026-06-01) with the
    `latexrelease.sty` built from the patched sources and
    `\RequirePackage[latest]{latexrelease}`. The sockets `caption/step` and
    `caption/listentry` exist, and `\caption*` does not step and writes no entry. It
    prints ": Star", because classes.cls is not part of latexrelease. The run reports 6
    errors ("Argument of \@p@pfilepath@aux has an extra }"). The unpatched develop
    `latexrelease.sty` gives the same 6 errors, so they do not come from this patch.
    (Not rerun on the combined patch.)
  - The first version of the guard, `\ifx\if@captionstar\@undefined`, would have broken
    the conditional nesting when skipped. It is now `\@ifundefined`.
- The patched `ltfloat.dtx` typesets with `source2edoc` without errors.

**Not verified:** the full base suite, base with XeTeX; the real caption.sty on top of
this (only the excerpt with stubs and the `captionclient.sty` sketch);
`\tagpdfsetup{float/split}` together with `\caption*`; real subcaption code on the
sub-float sockets (only the minimal sub-caption in float-020, the excerpt and
`captionclient.sty`); PDF/UA validation (veraPDF/PAC).

### 5. How caption would use it

caption.sty keeps today's path for older kernels and becomes a client when the socket
exists. The guard is `\IfSocketExistsTF{caption/listentry}`, which is equivalent to
`\IfFormatAtLeastTF{2026-11-01}` for releases but also works with a development format.
The excerpt below is `mwe/caption-excerpt.tex` and compiles as is (with stubs, see
section 4):

```latex
% caption.sty, new code path (excerpt).
% Kernels with the caption interface have the socket caption/listentry;
% older kernels take today's path (redefine \caption and \@caption).
\IfSocketExistsTF{caption/listentry}{%
  % list entries: caption's rules ([] = none, list=false,
  % sub-entries after the main entry) stay in \caption@addcontentsline
  \NewSocketPlug{caption/listentry}{caption}{\caption@addcontentsline{#1}{#2}}%
  \AssignSocketPlug{caption/listentry}{caption}%
  % \ContinuedFloat: the next \stepcounter of the float counter is skipped
  \AddToHook{cmd/caption/before}[caption]{\caption@ifcontinued\caption@skipnextstep{}}%
  % subcaption.sty: the sub-float context (inside subfigure, \subcaptionbox)
  \def\caption@subfloat@begin{\UseTaggingSocket{subfloat/begin}}%
  \def\caption@subfloat@end{\UseTaggingSocket{subfloat/end}}%
}{%
  \caption@AtBeginDocument{\caption@redefine}%
  \let\caption@subfloat@begin\relax
  \let\caption@subfloat@end\relax
}
\newcommand*\caption@skipnextstep{%
  \let\caption@ORI@stepcounter\stepcounter
  \let\stepcounter\caption@stepcounter@once}
\newcommand*\caption@stepcounter@once[1]{%
  \let\stepcounter\caption@ORI@stepcounter
  \edef\caption@tempa{#1}%
  \ifx\caption@tempa\@captype \else \stepcounter{#1}\fi}
% subcaption.sty: sub-captions step their own counter and use \@caption directly:
\newcommand*\caption@subcaption[2]{% #1 list entry, #2 text
  \refstepcounter{sub\@captype}%
  \@caption{sub\@captype}[#1]{#2}}
```

- caption keeps setting its own `\@makecaption` (`\caption@makecaption`). In the client
  path it also does there what its `\@caption` does today around `\@makecaption`: the
  type options (`\caption@beginex`) and the hypcap anchor.
- latex-lab replaces `\@makecaption` at `begindocument`. Proposal (c) gives that code a
  documented hook label, so that caption can remove it instead of overwriting it again.
- With (a), the `\@xfloat` wrapping in the old path is replaced by the float hook as
  well; the two changes are independent.
- `mwe/captionclient.sty` is a complete, compiled sketch of the same mechanics in expl3.
  It keeps the sub-entries back until the main entry is written and stores the link
  target of each sub-caption with its entry. Without that, the LoF links of the
  sub-entries would point to the main float.

### Open questions for the team

1. Is a kernel `\caption*` welcome? Should the classes test `\if@captionstar`, or an
   empty first argument as here? Can memoir, KOMA and amsart be told in advance?
2. `\ContinuedFloat`: would you rather have a documented flag ("this caption does not
   step the counter") that the kernel and the `caption/step` plug respect, instead of
   caption's local redefinition of `\stepcounter`?
3. Template-based `\caption`: caption documents `\caption[]{...}` as "no list entry",
   while the keyval conversion treats `[]` as "no keys" and offers `[{}]` instead. Would
   a template key (for example `list-entry={}` or `list=false`) be the way to say "no
   entry", with `[]` mapped to it for compatibility?
4. Sub-floats: is `Part` inside the minipage's `Div` acceptable, or should the sub-float
   socket replace the minipage structure? Should the kernel know `sub<type>` counters
   (for example through a `\NewSubCaptionType`), or is that left to packages?
5. Would hyperref (classic mode) also stop redefining `\caption`, so that the interface
   works without `\DocumentMetadata` too?

---

## (c) caption3's label format as a plug for the `caption/label` socket

Patch: series 0004 (`poc/proposals/patches/series/0004-*.patch`), on top of (b): it also
handles `\caption*`. There is no stand-alone version; without (b) only the `\caption*`
lines would have to go. Tests: `poc/proposals/tests/float-021-caption-label.*`,
`float-022-caption-separator.*`, `float-025-makecaption-label.*`,
`float-026-makecaption-voids.*`. caption-side code: `poc/proposals/mwe/caption3-labelplug.tex`,
`mwe/caption-sty-remove.tex`.

> **Changed 2026-10-06 (item 4).** The first version of (c) moved latex-lab's
> `begindocument` code for `\@makecaption` to a new label `latex-lab/float/makecaption`.
> That broke acmart, mitthesis, asmeconf and asmejour, which remove the code with
> `\RemoveFromHook{begindocument}[latex-lab-testphase-float]` (the workaround from
> tagging-project issue 720): the removal failed with "Cannot remove chunk", latex-lab's
> `\@makecaption` stayed active, and acmart with `\DocumentMetadata` printed "Fig. 1:
> First" instead of "Fig. 1. First" and "Fig. 1: Starred" for `\caption*`. (c) now keeps
> the label `latex-lab-testphase-float` and only documents it; caption.sty uses a `voids`
> rule. Measurements in section 4 and in "Verification of the combined patch" that are
> not marked "2026-10-06" were taken with the first version.

### 1. Problem

**What the socket does today.** latex-lab-float declares one plain socket for the label:

```latex
% required/latex-lab/latex-lab-float.dtx:692-712
% The argument is the label text.
% The default plug \texttt{kernel} adds a colon and a space.
% TODO: revisit after checking float and caption packages
% to identify which sockets and hooks are needed.
\NewSocket{caption/label}{1}
\NewSocketPlug{caption/label}{kernel}
 {
   #1:~
 }
```

Its only caller is latex-lab's own `\@makecaption`, which replaces the class definition
at `begindocument` (latex-lab-float.dtx:810). It uses the socket twice:

- once to measure, with tagging suspended (line 820:
  `\sbox\@tempboxa{\UseSocket{caption/label}{#1}#2}`);
- once to typeset, between the tagging sockets `caption/label/begin` and
  `caption/label/end` (lines 828-830, and 840-842 in the one-line branch).

The argument is the first argument of `\@makecaption`, i.e. the tokens
`\csname fnum@<type>\endcsname`. The plugs of the tagging sockets (lines 747-767) do
this:

- begin: call `\tagpdfparaOff`, then open the structure `float/<type>/label` (role `Lbl`)
  and an MC chunk;
- end: close both, then call `\tagpdfparaOn`.

So whatever the `caption/label` plug produces, the separator included, ends up in `Lbl`:

```text
Caption
  Lbl  "Figure 1:"          <- kernel plug "#1:~"
  P    "Kernel plug"
```

Others already use this socket:

- asmeconf.cls (lines 603-605) and asmejour.cls (lines 1110-1112) in TL 2026 assign
  `{\small\bfseries\sffamily ##1:\space}` and `{\bfseries\sffamily ##1\quad}`. The
  separator is inside the plug.
- latex-lab-listings.dtx:206-208 assigns `noop` for listing titles.
- latex-lab-table.dtx:1422-1427 does not use the socket at all: it has `#1{#2:~}#3`
  hard-coded for longtable captions.

The tagging sockets have a documented contract (lttagging.dtx:993-1000): "These sockets
are used in `\@makecaption` around the label. Their default plugs ensure that the label
is outside the paragraph and that the rest of the caption uses flattened para mode. If
the caption is not in a hbox, the `para/begin` socket should follow to properly start
the paragraph." So today they are meant for use *before* the caption paragraph.

**What caption3 does.** caption3 treats label, separator and text as three separate
pieces:

- Every caption format gets them as three arguments (caption3.dtx:4595-4615:
  `\caption@fmt{<label>}{<separator>}{<text>}`).
- The separator depends on `labelsep` (colon, period, space, quad, newline, ...).
- `labelfont` always covers the label, and covers the separator only when the separator
  was declared that way (`\caption@iflabelfont`).
- The label text comes from `labelformat`, through a redefinition of `\fnum@<type>`
  (`\caption@setfnum`, caption3.dtx:4010).
- `format=hang` needs label and separator as one box (`\@hangfrom{#1#2}`,
  caption3.dtx:2081).
- caption3 typesets the label *inside* the caption paragraph:
  `\caption@make@indention` does `\leavevmode` (caption3.dtx:4144-4147).

**Why caption must patch today, and what goes wrong.** Two problems, both compiled with
TL 2026:

1. `mwe/c-caption.tex`: caption.sty v3.6 with
   `labelformat=parens,labelsep=period,labelfont=bf,format=hang` under
   `\DocumentMetadata{tagging=on}`.
   - latex-lab's `\@makecaption` replaces caption's at `begindocument`, so only
     `labelformat` survives (it goes through `\fnum@figure`).
   - The PDF shows "Figure (1): A caption ..." in a normal font, without hanging
     indentation, and `Lbl` is "Figure (1):".

   To get its settings back, caption has to set `\@makecaption` again after latex-lab
   (the caption4 PoC does that in its `\AtBeginDocument` code) and tag the label itself.
2. `mwe/c-inpar.tex`: caption3 typesets the label inside the paragraph, so the label
   tagging sockets do not fit their contract:

   ```latex
   \UseTaggingSocket{caption/begin}{\@current@float@struct}%
   \noindent
   \UseTaggingSocket{caption/label/begin}Figure 1\UseTaggingSocket{caption/label/end}:
   Label inside the paragraph\par
   \UseTaggingSocket{caption/end}%
   ```

   - pdfLaTeX: "Package tagpdf Warning: nested marked content found - mcid 1" and "there
     is no mc to end at 2", and the label text appears twice in the structure (once in
     `P`, once in `Lbl`).
   - LuaLaTeX: the text after the label is lost from `P`; only `Lbl "Figure 1"` is left.

So the caption4 PoC (`poc/tex/caption3.sty`) uses tagpdf internals directly:

- it opens `\tag_struct_begin:n{tag=Lbl}` around the label only, with
  `\tag_mc_end_push:` and `\tag_mc_begin_pop:n{}` around it when in horizontal mode;
- it wraps all measuring in `\SuspendTagging{caption}`.

That works: 22/22 test documents are identical, with `Lbl` for every caption. But it
hard-codes the role `Lbl`, ignores `float/<type>/label`, and breaks whenever latex-lab
changes how it tags captions.

### 2. Proposed interface

All changes are in latex-lab (float and listings) and in the lttagging documentation.
No change to kernel code is needed.

1. **A documented contract for `caption/label`** (the text is in the patch):
   - The argument is the first argument of `\@makecaption`.
   - The socket is used twice, once to measure (with tagging suspended) and once to
     typeset, and must give the same result both times.
   - The plug produces horizontal material only: no `\par`, no writes, no counter steps.
   - The output goes into `Lbl`.
   - Any caption code may call the socket, not only latex-lab's `\@makecaption`.
2. **A new socket `caption/separator`** (0 arguments; the type is `\@captype`). It is
   used right after `caption/label/end` and `para/begin`, so the separator belongs to the
   caption text, not to `Lbl`. Plugs:
   - `kernel`: empty (assigned by default);
   - `colon`: `:~`.

   There is also a new plug `label-only` (`#1`) for `caption/label`.
   - The default output does not change: `kernel` + `kernel` still gives
     `Lbl "Figure 1:"`.
   - A document or class that wants the separator outside `Lbl` assigns `label-only` +
     `colon`.
   - Rule: code that suppresses the label by assigning `noop` to `caption/label` must
     also assign `noop` to `caption/separator`. Otherwise every such caption gets a stray
     ": " with `colon`. The patch does this in the two places that exist: listing titles
     (`\lst@maketitle`, latex-lab-listings.dtx:204-209) and `\caption*` ((b), in
     latex-lab's `\@makecaption`).
   - Plugs like the asme ones keep working as long as `caption/separator` keeps its
     default plug.
3. **`caption/label/begin` and `caption/label/end` also work inside the paragraph.** This
   extends the lttagging contract quoted above; it does not change it. The patch also
   updates the lttagging documentation.
   - If an MC chunk is open (`\tag_mc_if_in:TF`), begin interrupts it with
     `\tag_mc_end_push:` instead of calling `\tagpdfparaOff`, and end continues it with
     `\tag_mc_begin_pop:n{}`.
   - In latex-lab's own `\@makecaption` no chunk is open at that point, so its output
     stays the same.
   - Inside a paragraph, `Lbl` becomes a child of the caption's `P`, which is what the
     PoC produces today.
4. **A documented label for latex-lab's `\@makecaption`.** The `begindocument` code that
   replaces `\@makecaption` keeps the label it has today, the package's default label
   `latex-lab-testphase-float`; the patch documents it, says that it must not change
   (acmart, mitthesis, asmeconf and asmejour already remove the code by this label) and
   that it is the only code of latex-lab-float in `begindocument`.
   - A package that provides its own `\@makecaption` with tagging (built on the sockets
     `caption/begin`, `caption/end`, `caption/label/begin`, `caption/label/end` and
     `para/begin`/`para/end`) can keep its definition, instead of overwriting latex-lab's
     afterwards, with a rule (preferred)
     `\DeclareHookRule{begindocument}{<own label>}{voids}{latex-lab-testphase-float}`,
     where `<own label>` is the label of code it adds to `begindocument` itself, or with
     `\RemoveFromHook{begindocument}[latex-lab-testphase-float]`. The rule does not warn
     when the code is not there (no `\DocumentMetadata`) or a class has removed it
     already; `\RemoveFromHook` warns "Cannot remove chunk" in both cases.
   - As the label is not new, this item needs no code change; it works on develop
     today (`mwe/c-caption-remove.tex` gives the same output on unpatched develop).
   - This solves problem 1: caption's formatting (`labelsep`, `labelfont`, `hang`,
     margins, `singlelinecheck`) survives, and the tagging stays in kernel sockets.
5. **Plugs owned by caption3, not by the kernel:**
   - `caption3` for `caption/label` (label format + label font);
   - `caption3` for `caption/separator` (labelsep, in the label font if it was declared
     that way).

   They give caption3's label settings to every caption that still goes through
   latex-lab's `\@makecaption`, e.g. listings captions via latex-lab-listings, or classes
   that load caption3 without caption.sty. caption.sty itself uses item 4 and keeps its
   own `\@makecaption`, because formats such as `hang` cannot be expressed through a
   label socket.

Interaction: `caption/begin` / `caption/end` (lttagging.dtx:979-989) are unchanged and
still wrap the whole caption. With (d), the label structure is `float/<type>/label` or,
for an undeclared type, `float/generic/label`. latex-lab-table's longtable caption could
switch to the two sockets as well (not part of this patch).

### 3. Code sketch against latex2e develop

The full patch (latex-lab-float.dtx, latex-lab-listings.dtx, lttagging.dtx
documentation, `changes.txt`, two new tests) is series 0004. The core in
latex-lab-float (the contract is documented in the patch):

```latex
\NewSocket{caption/label}{1}
\NewSocket{caption/separator}{0}
...
\NewSocketPlug{caption/label}{label-only}
 {
   #1
 }
\NewSocketPlug{caption/separator}{kernel}{}
\AssignSocketPlug{caption/separator}{kernel}
\NewSocketPlug{caption/separator}{colon}
 {
   :~
 }
...
\bool_new:N \g_@@_caption_label_inpar_bool
\NewTaggingSocketPlug{caption/label/begin}{default}
  {
    \tag_mc_if_in:TF
      {
        \bool_gset_true:N \g_@@_caption_label_inpar_bool
        \tag_mc_end_push:
      }
      {
        \bool_gset_false:N \g_@@_caption_label_inpar_bool
        \tagpdfparaOff
      }
     \tag_struct_begin:n{tag=\UseStructureName{\@@_float_name:n{label}}}
     \tag_mc_begin:n{}
  }
% caption/label/end: \tag_mc_end: \tag_struct_end:, then
%   \tag_mc_begin_pop:n{} if the label was inside a paragraph, else \tagpdfparaOn
...
\AddToHook{begindocument}[latex-lab-testphase-float]   % label unchanged, now documented
  {
    \long\def\@makecaption#1#2{%
      ...
      \sbox\@tempboxa{\UseSocket{caption/label}{#1}\UseSocket{caption/separator}#2}%
      ...
      \UseSocket{caption/label}{#1}
      \UseTaggingSocket{caption/label/end}
      \UseTaggingSocket{para/begin}
      \UseSocket{caption/separator}
          #2
      ...
```

`\lst@maketitle` (latex-lab-listings) and the `\caption*` branch of (b) assign `noop`
to `caption/separator` as well.

### 4. Verification

These runs were made on (b) + (c) (results for the combined patch
are in the last section). Unless marked "2026-10-06", they were made with the first
version of item 4, which renamed the hook label (renamed label); the other items did not
change, and the 2026-10-06 runs below show that the rest of the output did not either.

- `l3build check -c config-float` (pdfTeX and LuaTeX): only `firstaid-float-H-2` and the
  three new tests (`float-020`, `float-021`, `float-022`) differ, and only in the
  `<PDF version="2.0">` line. That line differs the same way on the unpatched clone.
  (Renamed label.) 2026-10-06, on the latex2e branch with the label kept: the same ten
  `.diff` files with the same content as before, and the new `float-025` and `float-026`
  pass; `config-table-pdftex`, `config-table-luatex` and `config-block` give the same
  `.diff` files with the same content as with the renamed label.
- 2026-10-06, new tests for item 4 (one `.tlg` for both engines):
  `float-025-makecaption-label` removes the code as the classes do
  (`\RemoveFromHook{begindocument}[latex-lab-testphase-float]` in the preamble), and
  `float-026-makecaption-voids` disables it with a `voids` rule. In both, the class's own
  `\@makecaption` survives `\begin{document}` and is used for `\caption` and
  `\caption*`, without a warning. Both fail with the renamed label.
- Other latex-lab tests that use captions: `config-block firstaid-listings` (assigns
  `noop` to `caption/label`); `config-table-pdftex` / `config-table-luatex` with
  `table-012-caption`, `table-013-longtable-hyperref` and `table-021-longtable`;
  `tlb-context-001`. Same results as on the unpatched clone.
- New test `float-021-caption-label.lvt` (pdfTeX and LuaTeX `.tlg` saved with
  `l3build save`). Four cases, and the `\SHOWPDFTAGS` output is as intended:

  | case | `Lbl` | `P` |
  |---|---|---|
  | kernel plugs | "Figure 1:" | "Kernel plugs" |
  | `label-only` + `colon` | "Figure 2" | ": Separator outside Lbl" |
  | asme-style class plug | "Figure 3" (+ quad) | "Class plug, unchanged" |
  | label sockets inside a paragraph | "Figure 4", as child of `P` | ": Label inside the paragraph" |

  The last case is the `c-inpar.tex` code that fails today. With the patch it gives no
  warnings in either engine. In pdfTeX, `P` starts with an empty MC chunk before `Lbl`
  (the chunk that was open when the label started); LuaTeX has no such chunk.
- New test `float-022-caption-separator.lvt`, with `label-only` + `colon` for the whole
  document:

  | case | `Lbl` | text |
  |---|---|---|
  | listings `title=` | (none) | "My title" |
  | listings `caption=` | "Listing 1" | ": My caption" |
  | `\caption` | "Figure 1" | ": Numbered" |
  | `\caption*` | (none) | "Unnumbered" |

  Without the listings change, the title came out as ": My title".
- caption3 plug (`mwe/c-caption3-plug.tex`, pdfLaTeX and LuaLaTeX): `caption3` with
  `labelformat=parens,labelsep=period,labelfont=bf`, the two plugs, and latex-lab's
  `\@makecaption`. 0 errors in both engines. Output: "**Figure (1).** Short caption"
  (bold font in `pdffonts`). Structure: `Lbl "Figure (1)"`, then `P ". Short caption"`.
  The multi-line branch behaves the same.
- Item 4, with caption.sty 3.6 from TL 2026 (`mwe/c-caption-remove.tex` =
  `c-caption.tex` plus `\RemoveFromHook{begindocument}[latex-lab-testphase-float]`;
  2026-10-06, on the series with the label kept and on unpatched develop): 0 errors in
  both engines.
  - caption's formatting is back: "Figure (1). A caption ...", with the label in bold
    (SFBX/CMBX in `pdffonts`) and hanging indentation. Unpatched develop gives the same
    output, because the label is not new.
  - caption 3.6 has no tagging code, so there is no `Caption`/`Lbl` here. This only shows
    that the hook label works. The tagging part is the PoC run below.
  - The same document with `mwe/caption-sty-remove.tex` (the `voids` rule) in place of
    the `\RemoveFromHook` line gives the same output on the series. On unpatched develop
    that code does nothing, because the socket `caption/separator` does not exist.
  - Without `\DocumentMetadata`, `\RemoveFromHook` with this label warns "Cannot remove
    chunk" (`mwe/remove-notag.tex`), and so does a second removal after a class has
    removed the code. The `voids` rule warns in neither case (`mwe/voids-notag.tex`,
    with and without its first line), so caption.sty uses the rule (section 5).
  - With the label kept, acmart, mitthesis, asmeconf and asmejour (all of which remove
    the code by this label) were checked on 2026-10-06 (pdfLaTeX) against unpatched develop and
    TeX Live, with `\DocumentMetadata{lang=en}` (with and without hyperref),
    `tagging=on`, and with caption: no "Cannot remove chunk" any more, and the captions
    are the same as on develop and TeX Live (acmart: "Fig. 1. First", "Starred"). With
    the renamed label they were "Fig. 1: First", "Fig. 1: Starred". Remaining
    differences to develop do not involve the label: in asmejour and mitthesis `\caption*` no longer steps the counter
    ((b); "Fig. 2" instead of "Fig. 3" for the next caption), and under tagging acmart and
    asmeconf get one `Lbl` more, acmart also 14 instead of 10 errors (these tagging errors
    exist on develop as well).
- caption3 using the sockets: in the PoC caption3.sty I replaced the private tagpdf code
  with `\UseTaggingSocket{caption/label/begin|end}` ("sock"). In the PoC caption4.sty I
  also replaced the second `\let\@makecaption` at `\begin{document}` with
  `\RemoveFromHook` of latex-lab's code (renamed label) ("rm"). Five PoC test
  documents with tagging (`poc/tests/` t01, t02, t07, t10, t11), both engines: all 20
  runs 0 errors. "rm" vs "sock": identical structure trees (`pdfinfo -struct-text`), text
  and warnings. Every caption is a `Caption` with `Lbl`. No "Cannot remove chunk"
  warning. "sock" vs the original PoC code with private tagpdf calls: identical as well.
  (These modified PoC files are not part of `poc/proposals`, and these runs were not
  repeated on the combined patch or with the label kept.)

**Not verified:** PDF/UA validation (veraPDF/PAC); `labelsep=newline` with the caption3
plug (the contract forbids `\\`, see the open questions); latex-lab-table's longtable
caption with the sockets (not changed); latex-lab test configs other than those listed;
(c) without (b).

### 5. How caption would use it

In caption3.sty and caption.sty (new code), guarded by the existence of the new socket,
so older formats and older latex-lab versions take the old path
(`mwe/caption3-labelplug.tex` followed by `mwe/caption-sty-remove.tex`):

```latex
\ExplSyntaxOn
\IfSocketExistsTF { caption/separator }
  {
    \NewSocketPlug { caption/label } { caption3 }
      {
        \caption@setfnum { \@captype }   % \fnum@<type> -> caption3 labelformat
        \group_begin: \captionlabelfont #1 \group_end:
      }
    \NewSocketPlug { caption/separator } { caption3 }
      {
        \caption@labelseparator          % defines \caption@labelsep and \caption@iflabelfont
        \group_begin:
          \caption@iflabelfont \captionlabelfont \scan_stop:
          \caption@labelsep
        \group_end:
      }
    \cs_set_protected:Npn \caption@tag@lbl@begin { \UseTaggingSocket { caption/label/begin } }
    \cs_set_protected:Npn \caption@tag@lbl@end   { \UseTaggingSocket { caption/label/end } }
  }
  {
    % older latex-lab: caption3 keeps the private tagpdf code of the PoC here
    \cs_set_eq:NN \caption@tag@lbl@begin \scan_stop:
    \cs_set_eq:NN \caption@tag@lbl@end   \scan_stop:
  }
\ExplSyntaxOff
% caption.sty (not caption3): keep caption's own \@makecaption, which tags
% with the kernel sockets, instead of overwriting latex-lab's at \begin{document};
% a voids rule does not warn if a class has removed latex-lab's code already
\IfSocketExistsT{caption/separator}
  {\AddToHook{begindocument}[caption]{}%
   \DeclareHookRule{begindocument}{caption}{voids}{latex-lab-testphase-float}}
```

- `\caption@@@make` already calls `\caption@tag@lbl@begin` / `\caption@tag@lbl@end`
  around `#1` only (the label), so the separator stays outside `Lbl`, as in the proposed
  `label-only`/`colon` pair.
- caption.sty would assign the two `caption3` plugs only where it leaves captions to
  latex-lab's `\@makecaption`, not for its own captions.

### Open questions for the team

1. Should the separator be part of `Lbl` ("Figure 1:") or not ("Figure 1")? The default
   here stays as it is today. If you prefer "outside", latex-lab could switch its default
   to `label-only` + `colon` later, and caption would then match the kernel without any
   option.
2. Is `Lbl` as a child of `P` (label inside the paragraph) acceptable, or should the
   label sockets end the `P` and start a new one?
3. `labelsep=newline` and similar: should the contract allow vertical material in
   `caption/separator`, or should caption3 map those separators itself?
4. Should latex-lab-table's longtable caption use the same sockets instead of `#2:~`?
5. Is a documented hook label plus a `voids` rule (or `\RemoveFromHook`) the right way
   for a package to keep its own `\@makecaption`, or would you rather have a flag, or
   have latex-lab not redefine `\@makecaption` at all once the class code has the
   sockets? The label stays `latex-lab-testphase-float` because classes already use it;
   documenting it makes that name permanent, although it says "testphase".

---

## (d) Registering new float types for tagging (newfloat, and a kernel declaration)

Patches: `poc/proposals/patches/standalone/d-tagging-float-types.patch` (stand-alone)
and series 0002; newfloat: `poc/proposals/patches/newfloat-v1.2a.diff` (against
newfloat.dtx v1.2, 2023/10/01, as in TeX Live 2026). Test:
`poc/proposals/tests/float-017-declare.*`. Documents: `poc/proposals/mwe/d*.tex`.

**newfloat is a separate package.** It is no longer part of the caption bundle: Axel
Sommerfeldt moved it to its own repository, https://gitlab.com/axelsommerfeldt/newfloat,
in 2019 (caption commit df9f061, "newfloat package moved from this repository (and the
"caption package bundle") to https://gitlab.com/axelsommerfeldt/newfloat"). So
`fixes-combined` has no `source/newfloat.dtx`, and the newfloat part of this proposal is
a suggestion for newfloat's maintainer. I worked on the `newfloat.dtx`/`newfloat.ins`
from TeX Live 2026 (`texmf-dist/source/latex/newfloat`). caption's
`\DeclareCaptionType` uses newfloat.

### 1. Problem

Under `\DocumentMetadata{tagging=on}`, latex-lab only knows the float types `figure` and
`table`:

```latex
% required/latex-lab/latex-lab-float.dtx:222-224
\seq_new:N  \g_@@_float_types_seq
\seq_gput_right:Nn \g_@@_float_types_seq {figure}
\seq_gput_right:Nn \g_@@_float_types_seq {table}
```

A float of any other type gets the structure `float/generic` (latex-lab-float.dtx:543).
Its caption, however, asks for names that only exist for declared types:

```latex
% latex-lab-float.dtx:725 and 753 (plugs of caption/begin and caption/label/begin)
\tag_struct_begin:n{tag=\UseStructureName{float/\@captype/caption},firstkid}
\tag_struct_begin:n{tag=\UseStructureName{float/\@captype/label}}
```

`\UseStructureName` is `\cs:w l__tag_name_#1_tl\cs_end:` (lttagging.dtx:1283-1286), so
every `\caption` in such a float produces errors. This happens without caption or
newfloat. `mwe/d1-manual-float.tex` defines the type by hand, the way every float
package does (condensed):

```latex
\DocumentMetadata{tagging=on,debug={uncompress}}
\documentclass{article}
\makeatletter
\newcounter{diagram}
\def\fps@diagram{tbp}\def\ftype@diagram{4}\def\ext@diagram{lod}
\def\fnum@diagram{Diagram~\thediagram}
\newenvironment{diagram}{\@float{diagram}}{\end@float}
\makeatother
%\tagpdfsetup{float/new=diagram}% <- registration
\begin{document}
\section{Test}
Some text.
\begin{diagram} \centering A DIAGRAM \caption{A diagram caption}\label{d} \end{diagram}
\begin{figure} \centering A FIGURE \caption{A figure caption} \end{figure}
See diagram~\ref{d}.
\end{document}
```

TeX Live 2026 (latex-lab float 0.81n) gives 9 errors with pdfLaTeX and 14 with
LuaLaTeX:

```
Package tagpdf Warning: Parent-Child 'pdf2:P' --> 'pdf2:Aside'.
(tagpdf)                Relation is not allowed! on line 18
Package tagpdf Warning: tag \l__tag_name_float/diagram/caption_tl  is not known
! Undefined control sequence.
<argument> \l__tag_name_float/diagram/caption_tl
l.19 \caption{A diagram caption}
```

The PDF is broken: `pdfinfo -struct` reports `Syntax Error: StructElem object is wrong
type (\l__tag_name_float/diagram/caption_tl )`. The diagram has no `Caption` in the
tree, and its `Aside` sits inside the `P`. With `\tagpdfsetup{float/new=diagram}` there
are 0 errors, and the diagram is moved into its own `Sect` with `Caption` and `Lbl`.

The same happens with every package that defines float types (TL 2026):

| document | pdfLaTeX | LuaLaTeX |
|---|---|---|
| `d2-newfloat.tex` (`\DeclareFloatingEnvironment{diagram}`, `diagram` and `diagram*`) | 18 errors | 28 errors |
| `d3-newfloat-caption.tex` (the same + caption) | 18 | 28 |
| `d8-captiontype.tex` (caption's `\DeclareCaptionType`, which uses newfloat) | 9 | |
| `d11`/`d12` (newfloat with floatrowbytocbasic / floatrow) | 9 | |
| `d6-tocbasic.tex` (KOMA `\DeclareNewTOC[type=diagram,float]`) | 9 | |
| `d7-memoir.tex` (memoir `\newfloat`) | 9 | |
| `d4-float-sty.tex` (float.sty `\newfloat`) | 0, but the caption is not tagged at all (float.sty has its own `\caption`) | 0 |

The key `float/new` (latex-lab float 0.81m, 2025-12-04) fixes this. latex-lab uses it
itself for listings (`\tagpdfsetup{float/new=lstlisting}`, latex-lab-listings.dtx:193),
so it is the way a package is expected to register its float type today. But each
package has to know about it. Before 0.81p (2026-09-09, develop only), using it twice
for the same type is an error, so a package cannot simply call it. It is also only
defined when latex-lab-float is loaded.

### 2. Proposed interface

**(i) newfloat itself.** `\DeclareFloatingEnvironment` registers every new type. This
is done in `\newfloat@announce`, the macro that already tells tocbasic, memoir and
titletoc about the new type. If `latex-lab-testphase-float` is loaded (any
`\DocumentMetadata`), newfloat uses `\tagpdfsetup{float/new=<type>}`, but only if the
type is not yet known. The guard tests `\l__tag_name_float/<type>_tl`. That is internal,
see the open questions. Otherwise newfloat does nothing.

`\DeclareFloatingEnvironment` is preamble-only, and latex-lab-float is loaded by
`\DocumentMetadata` before the class, so the key is always there when it is needed.
caption's `\DeclareCaptionType` goes through `\DeclareFloatingEnvironment` and needs no
change. With the kernel declaration from (ii), `float/new` calls it, so newfloat gets the
kernel code without testing for a command name.

**(ii) The kernel: `\DeclareTaggingFloatType{<type>}`.** Everyone who defines float types
(newfloat, float.sty, tocbasic, memoir, classes, hand-written `\@float` environments)
should have one declaration that works with and without tagging:

- `\DeclareTaggingFloatType{<type>}` goes in `lttagging.dtx`. It is part of the format,
  so it is always defined, also without `\DocumentMetadata`. `<type>` is the argument of
  `\@float`, the value of `\@captype`.
- It adds the type to `\g__tag_float_types_seq`, which moves from latex-lab-float to
  lttagging. It also declares the structure names `float/<type>s` (role `Sect`),
  `float/<type>` (`float`), `float/<type>/caption` (`Caption`) and
  `float/<type>/label` (`Lbl`). That is exactly what `float/new` does today. Together
  with (b) it also declares `float/<type>/sub` (`Part`).
- It can be called more than once for the same type. A name that already has a role is
  not changed, so roles assigned with `\AssignStructureRole` in between are kept.
- **Local roles.** It belongs in the preamble, outside of a group. As with
  `\NewStructureName` and `\AssignStructureRole`, the roles are set locally, while the
  type list is global. If the only declaration is inside a group, the type is known
  afterwards but its names are empty: no TeX error, but tagpdf warns (`tag  is not
  known`) and the tags are wrong (`mwe/d10b-declare-only-in-group.tex`, 16 tagpdf
  warnings). A later declaration outside the group assigns the roles again
  (`mwe/d10-declare-in-group.tex`, test `float-017-declare`). The first version of this
  proposal skipped known types completely and could not repair this. The existing
  `float/new` key has the same local/global mix. I did not change that, because the l3
  naming rules tie `l_` variables to local assignments, and you will know better whether
  the names should become global.
- `\tagpdfsetup{float/new=<type>}` keeps working: it calls `\DeclareTaggingFloatType`
  and keeps its info message for known types (test `float-016-new` unchanged).

**Name.** The first draft of this proposal used `\DeclareFloatType`, but
floatrowbytocbasic (TL2026, v1.0 2023-08-16) already defines `\DeclareFloatType` as a
copy of floatrow's `\DeclareNewFloatType` (floatrowbytocbasic.sty:32-33) and then patches
it. With a kernel `\DeclareFloatType`, `\usepackage{floatrowbytocbasic}` stops with
`Command \DeclareFloatType already defined`. `\DeclareTaggingFloatType` does not occur
anywhere in `texmf-dist/tex` or `texmf-dist/source` of TeX Live 2026 (`grep -rlw`), and
it says what the command does today. floatrow's `\DeclareNewFloatType` and
floatrowbytocbasic's `\DeclareFloatType` are different commands: they set up the whole
float environment.

**(iii) Robustness for undeclared types.** When `float/<type>/caption` does not exist,
the caption plugs use `float/generic/caption` and `float/generic/label` (new names in
latex-lab-namespace). An undeclared type then gives no errors. It still gets the
generic, non-deferred structure as before, and `float-012-unknown` is unchanged. In the
series, (b)'s sub-floats use the same fallback (`float/generic/sub`).

I did not make latex-lab register unknown types automatically at the first float.
`\@xfloat` runs inside a group and `\AssignStructureRole` is local (see above), and
authors could not assign roles before the first use. It would also change
`float-012-unknown`. See the open questions.

**Interaction.** No socket changes. The `float/begin` and `float/end` tagging sockets
keep using `\g__tag_float_types_seq`. The float.sty `[H]` firstaid
(latex-lab-firstaid.dtx:1458-1464) uses `float/##1` directly, so `[H]` floats of an
undeclared type still break. I did not touch it.

**Compatibility.** The new public name is unused in TeX Live 2026 (see above). With the
patched kernel, floatrowbytocbasic loads without errors (`mwe/d9-floatrowbytocbasic.tex`).
The only change in existing test output is the tagpdf debug echo in `float-010-outside`.
It now shows the unexpanded option `tag=\UseStructureName {\__tag_float_name:n
{caption}}` (and `{label}`) instead of `tag=\UseStructureName {float/\@captype
/caption}`. The resolved tag is still `Caption`. The updated `.tlg` files are in the
patch.

### 3. Code sketch against latex2e develop

The full patch changes `base/lttagging.dtx`, `required/latex-lab/latex-lab-float.dtx`
(the type list moves out; the body of `float/new` becomes `\DeclareTaggingFloatType{#1}`;
the caption plugs use the helper below), `required/latex-lab/latex-lab-namespace.dtx`
and `changes.txt`, and adds the test `float-017-declare`. The new code in lttagging
(series version, with the `/sub` line from (b)):

```latex
\seq_new:N \g_@@_float_types_seq
\seq_gput_right:Nn \g_@@_float_types_seq {figure}
\seq_gput_right:Nn \g_@@_float_types_seq {table}
\cs_new_protected:Npn \DeclareTaggingFloatType #1
  {
    \seq_if_in:NnF \g_@@_float_types_seq {#1}
      { \seq_gput_right:Nn \g_@@_float_types_seq {#1} }
    \@@_float_type_name:nn {float/#1s}         {Sect}
    \@@_float_type_name:nn {float/#1}          {float}
    \@@_float_type_name:nn {float/#1/caption}  {Caption}
    \@@_float_type_name:nn {float/#1/label}    {Lbl}
    \@@_float_type_name:nn {float/#1/sub}      {Part}   % with (b)
  }
\cs_new_protected:Npn \@@_float_type_name:nn #1#2
  {
    \tl_if_exist:cF { l_@@_name_#1_tl }
      { \NewStructureName {#1} \tl_clear:c { l_@@_name_#1_tl } }
    \tl_if_empty:cT { l_@@_name_#1_tl }
      { \AssignStructureRole {#1} {#2} }
  }
```

In latex-lab-float, the caption plugs use

```latex
\cs_new:Npn \@@_float_name:n #1
  {
    float/
    \cs_if_exist:cTF { l_@@_name_float/\@captype/#1_tl }
      { \@captype } { generic }
    /#1
  }
% \tag_struct_begin:n{tag=\UseStructureName{\@@_float_name:n{caption}},firstkid}
% \tag_struct_begin:n{tag=\UseStructureName{\@@_float_name:n{label}}}
```

and latex-lab-namespace adds `float/generic/caption` (`Caption`) and
`float/generic/label` (`Lbl`).

newfloat v1.2a (`patches/newfloat-v1.2a.diff`, `\CheckSum` updated, "Checksum passed"),
in `\newfloat@announce`:

```latex
  \newfloat@tagging@register{#1}%
  \newfloat@hook{#1}}
...
\newcommand*\newfloat@tagging@register[1]{%
  \@ifpackageloaded{latex-lab-testphase-float}%
    {\ifcsname l__tag_name_float/#1_tl\endcsname \else
       \newfloat@Info{Registering float type `#1' for tagging}%
       \tagpdfsetup{float/new={#1}}%
     \fi}%
    {}}
\@onlypreamble\newfloat@tagging@register
```

### 4. Verification

These runs were made on the stand-alone patch (results for the
combined patch are in the last section).

- **latex-lab** `l3build check -c config-float` (all float/marginpar tests including the
  new one and the PDF-based `.pvt` ones, pdfTeX and LuaTeX). Everything passes except
  `firstaid-float-H-2` (the same on the unpatched copy, see the last section) and
  `float-010-outside`, which differs only in the debug echo above and now has new `.tlg`
  files. `float-012-unknown(-log)`, `float-013-new` and `float-016-new` are unchanged.
- **New test** `float-017-declare.lvt` contains:
  - `\DeclareTaggingFloatType{diagram}` twice, `\DeclareTaggingFloatType{figure}` and
    `float/new=diagram` (info only);
  - `chart`, declared inside a group (the `.tlg` shows the caption role `''` after the
    group) and then again outside (`'Caption'`);
  - a float of each declared type and one of an undeclared type, all with `\caption`,
    plus `\SHOWPDFTAGS`.

  It gives 0 errors with pdfTeX and LuaTeX. `diagram` and `chart` are deferred into a
  `Sect` with `Caption`/`Lbl`. The undeclared `scheme` stays in the flow as a generic
  `float` (Aside), now with `Caption`/`Lbl`. The `.tlg` was saved with my local
  show-pdf-tags, which writes `<PDF>`; it now has `<PDF version="2.0">` like the other
  `.tlg` files in the repository, so locally it differs in that line only.
- **Documents on the patched kernel**, pdfLaTeX and LuaLaTeX:
  - `d1` (hand-made type, no packages): 0 errors (was 9/14), `Caption` and `Lbl`
    present. The generic float still sits inside the paragraph (the existing `P` →
    `Aside` warning).
  - `d2` with newfloat v1.2: 0 errors (was 18/28), generic structure. With newfloat
    v1.2a: 0 errors, 0 tagpdf warnings, deferred `Sect`.
  - `d6` tocbasic and `d7` memoir: 0 errors (were 9 each), from (iii) alone.
  - `d9` floatrowbytocbasic: 0 errors (with the first draft's `\DeclareFloatType`: 7
    errors, `Command \DeclareFloatType already defined`).
  - `d10` (declared in a group, then again): 0 errors, 0 tagpdf warnings, 0
    `pdfinfo -struct` errors. `d10b` (only in a group): 0 errors, 16 tagpdf warnings,
    the limitation described in 2(ii).
- **newfloat v1.2a on unchanged TeX Live 2026** (latex-lab 0.81n, so the `float/new`
  path; not repeated on the combined patch, as it does not use the kernel patch):
  - `d2` and `d3`: 0 errors and 0 tagpdf warnings with pdfLaTeX and LuaLaTeX (were
    18/28). The structure tree has both diagrams in their own `Sect` with `Caption`,
    `Lbl` and the List of Diagrams.
  - `d8` (`\DeclareCaptionType`): 0 errors (was 9).
  - newfloat with article, scrartcl, memoir and report under tagging: 0 errors each
    (were 9).
  - Without `\DocumentMetadata`, nothing is registered and there are no errors. With
    `\DocumentMetadata{}` (tagging off), the type is registered without errors.
  - **Name clashes** (`d11`, `d12`): newfloat together with floatrowbytocbasic and with
    floatrow, without metadata gives 0 errors with v1.2 and with v1.2a. Under tagging it
    gives 9 errors with v1.2 and 0 with v1.2a. The first draft of v1.2a tested
    `\ifdefined\DeclareFloatType` and then called floatrowbytocbasic's two-argument
    command, which gave 44 errors even without tagging.
- **newfloat's own tests** in the caption suite (`test/newfloat`, 5 documents, no
  tagging): with the first draft of v1.2a, identical text with v1.2 and v1.2a.
  `figurewithin-3` fails in both (it does not load newfloat). Not rerun for the current
  v1.2a, which only drops the `\ifdefined` branch, a branch that is never taken without
  the kernel change.
- The documentation of the patched `lttagging.dtx` typesets without errors.

**Not verified:** the full latex-lab test suite (only `config-float`), XeTeX, validation
with veraPDF/PAC, typesetting `latex-lab-float.dtx`, and other packages actually calling
`\DeclareTaggingFloatType` (only the fallback (iii) was tested for tocbasic/memoir).

### 5. How caption (newfloat) would use it

newfloat v1.2a needs no test for the kernel command (code in section 3). On a kernel
with (ii), `float/new` calls `\DeclareTaggingFloatType`. Once (ii) is in a release,
newfloat could also declare the type without tagging, guarded by the format date and not
by the existence of a name:

```latex
  \IfFormatAtLeastTF{<release date>}%
    {\DeclareTaggingFloatType{#1}}%
    {<the code above>}%
```

caption itself defines float types only through newfloat (`\DeclareCaptionType`), so
caption.sty needs no change for this. subcaption's sub-types are counters, not floats;
for sub-figures see the sub-float sockets in (b).

### Open questions for the team

1. Name: `\DeclareTaggingFloatType`, or keep only the key and make
   `\tagpdfsetup{float/new=...}` safe to call without `\DocumentMetadata`?
   (`\DeclareFloatType` is taken by floatrowbytocbasic.)
2. Should the names of a float type be assigned globally, so that a declaration inside a
   group works? That would also apply to `float/new`.
3. Should the kernel register unknown types automatically at their first float, instead
   of the generic structure? That needs a global role assignment and changes
   `float-012-unknown`.
4. Can there be a public test for "this float type is known" (instead of testing
   `\l__tag_name_float/<type>_tl`)? (Compare (a), question 4.)
5. Should the declaration later also take the rest of the float setup (counter, `\fps@`,
   `\ftype@`, `\ext@`, `\fnum@`), so that newfloat, float.sty, tocbasic and memoir can
   share one kernel declaration? Then a more general name would be needed.
6. float.sty `[H]` floats and restyled floats: the firstaid uses `float/<type>` directly,
   and float.sty's own `\caption` is not tagged. Is that planned on your side? (Compare
   (a), question 3.)

---

## Verification of the combined patch

All four kernel patches applied in sequence (`patches/series/0001`–`0004`, the same
content as `patches/combined.diff`) to a fresh copy of develop 829e56a15, compared with
an unpatched copy of the same commit. The stand-alone patches (a), (b) and (d) were also
applied alone to fresh copies. Every l3build and TeX run had a time limit. The scripts
are in `poc/proposals/scripts/`; `poc/proposals/README.md` explains how to rerun them.

**Taken with the renamed label.** The tables below were measured with the first version
of (c), which renamed latex-lab's hook label (see (c), "Changed 2026-10-06"). After the
change, series 0004 and `combined.diff` were regenerated from the latex2e branch, and on
that branch (an export, not the series applied by `run-checks.sh`) latex-lab
`config-float`, `config-table-pdftex`, `config-table-luatex` and `config-block` gave the
same `.diff` files with the same content as before; the two new tests `float-025` and
`float-026` pass in both engines and fail with the renamed label. The series still
applies to 829e56a15 and gives the tree of the branch. The base tests and
`config-lthooks` were not rerun: (c) changes no base file except the lttagging
documentation, and the change touches latex-lab-float only. The client documents were
not rerun on the combined patch; `c-caption-remove` was rerun on a format built from the
branch (see (c)4).

**About the `<PDF version="2.0">` line.** The `.pvt`-style latex-lab tests print the
structure with show-pdf-tags. The `.tlg` files in the repository contain
`<PDF version="2.0">`; my local show-pdf-tags writes `<PDF>`. So `firstaid-float-H-2`,
`firstaid-listings` and (LuaTeX) `table-015-hhline` fail locally on unpatched develop,
and the new tests 017, 020, 021 and 022 (whose
`.tlg` files have the repository's line) fail locally in exactly that one line
(`float-025` and `float-026` print no structure and pass). They
may need to be saved again on your setup.

### l3build

| Check | develop 829e56a15 | combined (a)+(d)+(b)+(c) |
|---|---|---|
| base, pdfTeX + LuaTeX: `tlb-float-hooks-001`, `tlb-float-hooks-002-rollback`, `caption-interface-001`, `tlb0002a`, `tlb-fltrace-000`, `tlb-hfloat-01`, `tlb0018`, `tlb1893`, `tlb2400`, `tlb2815`, `tltx001`, `tl2e8`, `github-robust-0123`, `tlb-latexrelease-rollback-001`, `-002`, `-003-often`, `-004`, `-2025-11-01`, `-2026-06-01`, `-2026-11-01` | the 17 existing tests pass (the 3 new ones do not exist) | all 20 pass in both engines |
| base `config-lthooks` (99 tests, pdfTeX) | all pass | all pass (16 `.tlg` files updated by (a)) |
| latex-lab `config-float` (pdfTeX + LuaTeX) | 24 tests; only `firstaid-float-H-2` differs (`<PDF>` line) | 28 tests; `firstaid-float-H-2` and the new 017, 020, 021, 022 differ only in the `<PDF>` line; all others pass, including `float-010-outside` with its updated `.tlg` and `float-tagging-off` |
| latex-lab `config-table-pdftex` (37 tests) | all pass | all pass |
| latex-lab `config-table-luatex` (30 tests) | `table-015-hhline` differs (`<PDF>` line) | identical difference |
| latex-lab `config-block firstaid-listings` (pdfTeX + LuaTeX) | differs (`<PDF>` line) | identical difference |
| stand-alone (a): base list above + `config-lthooks`, `config-float` | | base: all pass except `caption-interface-001`, which belongs to (b) and is absent; `config-lthooks`: all pass; `config-float`: only `firstaid-float-H-2` (`<PDF>` line) |
| stand-alone (b): base list, `config-float` | | base: all pass except the two (a) tests (absent); `config-float`: `firstaid-float-H-2` and `float-020`, `<PDF>` line only |
| stand-alone (d): `config-float` | | `firstaid-float-H-2` and `float-017`, `<PDF>` line only |
| all patches apply with `git apply` | | series in order on 829e56a15; (a), (b), (d) stand-alone each on 829e56a15 |

The `.tlg` files of the rollback tests were also regenerated for XeTeX (they have
XeTeX-specific versions), but no other XeTeX run was made.

### Client documents

Compiled against the formats built by l3build from the combined tree (and, for
comparison, from unpatched develop), with caption v3.6p from `fixes-combined` ("stock
caption"), the same with `patches/caption-floathooks.diff` ("caption with hooks"), and
newfloat v1.2a. Three runs each (two for the simpler ones).

| Document | Result on the combined patch |
|---|---|
| (a) `a2-caption-user` (two-column, babel-french, hyperref, type options) | 0 errors; text and `.aux` of "caption with hooks" on the combined patch are identical to stock caption on unpatched develop; `\@xfloat`/`\@xdblfloat` are the kernel's |
| (a) `a3-caption-user-tagging` (a2 under tagging) | 0 errors, 0 tagpdf warnings; text, `.aux` and structure tree (`pdfinfo -struct-text`) identical to stock caption on unpatched develop |
| (a) `a4-nested-H` | one `BEGIN figure []`, one `END figure [] captype=figure`, 0 errors |
| (a) `a5-plain`, `-setspace`, `-float`, `-xdbl`, `-bypass`, `-rollback` | 0 errors; `\caption@settype` once per float, `figure*` options once; wrapping as described in (a)4; text identical to stock caption |
| (b) `client-doc`, `-notag`, `-notag-hyperref` (pdfLaTeX, LuaLaTeX) | 0 errors in all six runs; `.lof` files and (with tagging) structure trees identical to the runs on (b) alone; the only tagging warning is "Parent-Child 'Link' --> 'Link'" |
| (b) `caption-excerpt-doc` | 0 errors |
| (b) `cls-star` with article, report, memoir, scrartcl, amsart | as in (b)4: "Starred" / ": Starred" / ". Starred", no LoF entry, right numbers |
| (b) `release-back` | old behaviour: "Figure 2: \*", LoF entry "\*" |
| (c) `c-caption3-plug`, `c-caption-remove`, `c-inpar` (pdfLaTeX, LuaLaTeX) | 0 errors; structure trees identical to the runs on (b)+(c); `c-inpar`: `Lbl` as child of `P`, no tagging warnings |
| (d) `d1`, `d2` (newfloat v1.2 and v1.2a), `d3`, `d10`, `d10b` (pdfLaTeX, LuaLaTeX) | 0 errors (on develop: `d1` 9/14, `d2` with v1.2 18/28, `d2` and `d3` with v1.2a 0, `d10` 22/25, `d10b` 21/24; `d3` is compiled with v1.2a only); `d2`/`d3` with v1.2a: 0 tagpdf warnings; `d10b`: 16 tagpdf warnings, as described in (d) |
| (d) `d6`, `d7`, `d8`, `d9`, `d11`, `d12` with newfloat v1.2a (pdfLaTeX) | 0 errors, 0 tagpdf warnings (on develop: `d6`, `d7` 9 errors each) |

### What was not verified

- The full l3build test suites of base and latex-lab (only the configurations and tests
  listed above), and XeTeX apart from saving the rollback `.tlg` files.
- PDF/UA validation (veraPDF, PAC) of any of the tagged output.
- A caption.sty that uses (a), (b) and (c) together. The client code exists as three
  separate pieces (`patches/caption-floathooks.diff`, `mwe/captionclient.sty` and
  `mwe/caption-excerpt.tex`, `mwe/caption3-labelplug.tex`), each tested on its own.
- Real subcaption code on the sub-float sockets.
- On the combined patch, these runs of the single-patch verification were not repeated:
  the caption test suite with the hook (a), the `latexrelease` roll-forward (b), the PoC
  "sock"/"rm" comparison (c), the newfloat runs on unchanged TeX Live (d), and
  typesetting the documentation of the changed `.dtx` files.
- (c) without (b), and (c) on top of the stand-alone (b) (the series puts it after (d)).
