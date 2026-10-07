## (b) A caption interface: `\caption*`, list entries, sub-captions (version 2)

> **DRAFT, not sent.** 2026-10-06, updated 2026-10-07 for the split series. This replaces
> version 1 of (b) (2026-10-04; the old text is in the git history of `poc/PROPOSALS.md`). The
> long working version with all measurements and review findings is `PROPOSAL-b-v2.md` in the
> caption branch `poc-b2` (folder `poc-b2/`). This file is section (b) of `poc/PROPOSALS.md` on
> its own.

Patches (in `poc/proposals/patches/b-v2/`, with a cover letter `COVER.md`):
- `series/0001-0014`: (a), (d), O2 and (b) in parts, with (c) after b-4, as 14 commits on
  latex2e develop **2a9bfe9d6** (2026-10-06); `git am` gives latex2e branch `b2-split`, head
  449aa8e30. Version 1 of (b) is not in it: its content is folded into the parts b-3a, b-4 and
  b-6, and `classes.dtx` is not changed. The 28-patch prototype on top of the version-1 series
  and its replay on 2a9bfe9d6 are in the git history of this folder.
- `O1.patch` (optional, on top of the series) and `O2-standalone.patch` (O2 alone on develop,
  for a first small PR).
- `caption-client.diff`: caption as a client (against the caption PoC a518ec6); it takes its
  client path only when `\@kernel@@caption` is defined, i.e. from part b-5 on.

Tests (copies in `poc/proposals/tests/b-v2/`, one set per part, see (b)4): base
`caption-outside-001`, `caption-interface-001` to `-007` (`-008` with O1); latex-lab
`float-020` to `float-030`; firstaid `firstaid-float-caption`, `-hyperref`; and the tests of (a)
and (d).

Every commit passes the base suite in pdfTeX, XeTeX and LuaTeX, the hook configurations, the
other base configurations, firstaid and latex-lab `config-float` on its own; the head also all
latex-lab CI configurations and `required/tools`.

### 1. Problem

The kernel `\caption` and `\@caption` have no entry points: `\refstepcounter\@captype` and the
`\addcontentsline` are hard-coded, and there is no star form. So caption.sty, latex-lab-float,
hyperref (without `\DocumentMetadata`), float.sty, memoir, beamer, rlbabel and classes such as
llncs each redefine one or both, and the last definition wins. With tagging, caption's and
latex-lab's definitions overwrite each other. On develop, `\caption*{Starred}` prints
"Figure 2: \*", then "Starred", and writes the LoF entry "2 \*".

Version 1 (`\caption*`, sockets `caption/step` and `caption/listentry`, tagging sockets
`subfloat/begin|end`) was implemented in caption as a real client. It was not enough:
- the client could use it in only 290 of 488 test runs (float.sty, classic hyperref, memoir,
  beamer and rlbabel replace `\caption`), and had to test the *meaning* of the macros;
- there was no point after the star and the arguments are known, so caption still intercepted
  `\stepcounter` and `\@dblarg` (`\caption{}` and `\caption[]{x}` could not be told apart);
- no point at float level (caption's per-caption setup needs the float's group and
  `\linewidth`);
- no way to say "do not step" or "no target", so continued captions made duplicate
  destinations;
- sub-floats were one level too deep (`Div` > `Part`).

Two latex-lab bugs came up as well: after `float/split`, and for a `table` caption inside a
figure, the caption target does not exist ("has been referenced but does not exist").

### 2. Interface

For `\caption[o]{t}` in a float (type = the expansion of `\@captype`):

| step | where | what | for `\caption*` |
|---|---|---|---|
| 0 | `\caption` | generic hook `cmd/caption/before` (unchanged) | yes |
| 1 | `\caption` | outside a float: error; then the star and both arguments are skipped (O2) | yes |
| 2 | `\caption` | `\@kernel@caption@reset`: end the settings of an earlier `\caption*` (step 5a), switches to their defaults | yes |
| 3 | `\caption` | read `*`, `[o]` (absent: `\NoValue`) and `{t}` | yes |
| 4 | `\caption` | hook **`caption/before`** {type}{`\BooleanTrue`/`\BooleanFalse`}{o}{t} | yes |
| 5 | `\caption` | socket **`caption/step`** {type} | no |
| 5a | `\caption` | if the counter was not stepped: settings for a replaced `\@caption` | yes |
| 6 | `\caption` | `\@caption{type}[o or t]{t}` (still the last token) | yes |
| 7 | `\@caption` | undo 5a, `\par` | yes |
| 8 | `\@caption` | hook **`caption/prepare`** {type}{star}{list text}{t} | yes |
| 9 | `\@caption` | socket **`caption/listentry`** {type}{list text}{t} | no |
| 10 | `\@caption` | socket **`caption/typeset`** {type}{star}{t}; the kernel plug calls `\@makecaption` | yes |
| 11 | `\@caption` | `\@kernel@caption@reset` | yes |

With the default plugs and empty hooks, `\caption` gives the same output as today.

**New names.**

| name | kind | default / use |
|---|---|---|
| `\caption*` | kernel star form | no step, no target, no list entry; `\@makecaption{\@caption@nolabel}{text}` with `\if@captionstar` true |
| `caption/before`, `caption/prepare` | hooks, 4 arguments | empty; caption (step and list decisions; anchor), possibly hyperref, nameref, memoir |
| `caption/step` | socket, 1 argument | `\@kernel@caption@step`; latex-lab no longer plugs it |
| `caption/listentry` | socket, 3 arguments (v1: 2) | today's `\addcontentsline` |
| `caption/typeset` | socket, 3 arguments | `\@kernel@caption@typeset` (today's code, at float level) |
| `\if@captionstar`, `\if@captionstep`, `\if@captiontarget` | legacy switches | false, true, true; the last two may be set false in `caption/before` |
| `\@caption@nolabel` | robust command | the label of `\caption*`: typesets nothing |
| `\@kernel@caption`, `\@kernel@@caption` | copies of `\caption`, `\@caption` | availability test (`\ifdefined\@kernel@caption`); a client may restore them |
| `\@kernel@caption@reset` | command, 0 arguments | ends the settings of a `\caption*`; for code that keeps its own numbered `\caption` and passes only `\caption*` to the kernel |
| `\@kernel@caption@unique` | command: {counter}{code} | runs code while `\theH<counter>` has the next unique suffix `*<n>`, then restores it; no group; for code that makes the target of an unstepped caption itself |
| `\@floatHref@<type>` | latex-lab state, documented | the target of the current float of that type |
| `subfloat/box` | tagging socket, 0 arguments | the next `minipage`/`\parbox` is a sub-float (`Part` instead of `Div`) |

The `\@kernel@...` commands are undefined after a `latexrelease` roll-back; the hooks, sockets and switches stay defined (unused), so
`\IfHookExistsTF` is not a valid test.

**Contracts.**
- **Step and target.** A `caption/step` plug wraps everything in the socket `refstepcounter`,
  steps only if `\if@captionstep`, always sets `\@currentcounter` and `\@currentlabel`, and only
  if `\if@captiontarget` uses `\@floatHref@<type>` or makes a target (with `recordtarget`). With
  `\@captiontargetfalse` nothing is recorded. This replaces caption's use of `\if@skiphyperref`.
- **Captions that do not step** (continued floats) get a target with a unique name,
  `<counter>.<\theH<counter>>*<n>` (`figure.1*1`), counted per name, or the float target inside
  a tagged float. So there is no duplicate destination, and a `\label` points to the continued
  caption itself.
- **`\caption*`** does not step, makes no target and writes no list entry; `\@currentlabel`
  stays as after `\section*`. The class's `\@makecaption` is called with `\if@captionstar` true
  and the label `\@caption@nolabel`. Testing the switch is the only documented way for a class
  to support `\caption*`. The standard classes are *not* changed: babel-french and caption3
  recognise them by comparing `\@makecaption` with its standard definition.
- **Separator removal (optional convenience).** For the many `\@makecaption` definitions that
  do not test the switch, `\@caption@nolabel` removes a following `:`/`.` and spaces (also after
  `\textbf{#1}` or `{\bfseries #1:}`), starts the paragraph by a rule (before mode-dependent
  primitives and `\\`, `\newline`, `\@`), and warns once if something else is printed. About 70
  lines; without it the contract still holds.
- **A replaced `\@caption`** (llncs, mwcls and others; threeparttable defers it): for an
  unstepped caption the kernel sets `\theH<type>` with the unique suffix, and for `\caption*`
  also `\fnum@<type>` to the empty label and `\ext@<type>` to empty, until the next `\caption`
  or the end of the group. Such classes then give a clean `\caption*` in their own layout.
- **latex-lab.** Its `caption/step` plug goes; the float target is stored per type at the float
  start and after `float/split` (fixes both bugs above); captions with an undefined
  `\@captype` get `generic` structure names; `\caption*` uses `nolabel` plugs of
  `caption/label/begin|end`; latex-lab's `\@makecaption` tests `\if@captionstar`.
- **float.sty** (first aid, only for v1.3d): float's numbered `\caption` is kept, `\caption*`
  goes to the kernel with float's style for that caption.
- **Optional:** O1, `\@caption` sets `\@currentlabelname` (so `\nameref` to a caption gives the
  caption, not the last heading; might better live in nameref through `caption/prepare`); O2,
  skip the arguments after "`\caption` outside float".

### 3. Compatibility and limits

- Without clients, output is unchanged (8 classes × 4 modes and 23 package documents against
  develop), except `\caption*`, the latex-lab target fixes and, with O1, the third field of
  `\newlabel`.
- Captions no longer go through `\refstepcounter` (cleveref still works through the kernel's
  `label` hook; checked). `\@kernel@caption@step` repeats its body.
- Targets of unstepped captions are renamed (`figure.1*1`), also where a client had already
  made them distinct (`.aux` and tagging data only).
- **`\caption*` cannot reach** code that replaces `\caption`: classic hyperref, beamer, and
  classes such as aastex701, mnras, tufte-book, uwthesis keep the old output. Two hyperref
  sketches were tested (route only the star to `\@kernel@caption*`, or stop patching when
  `\@kernel@caption` exists); beamer needs `\caption*` in its templates. KOMA, memoir, AMS and
  babel-french print their separator with a warning; one `\if@captionstar` test each would fix
  that. Of 85 TL classes that compile with pdfLaTeX, 50 give a clean `\caption*`.
- Known gaps: O1 overwrites titles that memoir or nameref sanitised (so O1 is optional); with
  hyperref's `naturalnames=true`, captions left unstepped by other code still give duplicates.
  Resolved in the split: `subfloat/box` needs no group any more, and `\@kernel@caption@unique`
  also works after a `\caption*` handled by a replaced `\@caption`.
- Size: the non-comment lines of ltfloat.dtx grow from 390 (develop 2a9bfe9d6) to 686 (the
  series); b-3a alone has 91 of them, b-3b 41, b-3c 54, b-3d 87.

### 4. Parts (the series) and their state

latex2e branch `b2-split` on develop 2a9bfe9d6 (`patches/b-v2/series/`; not pushed, not posted):

| # | part | commit | content | tests |
|---|---|---|---|---|
| 0001 | (a) | 2e1246c7c | hooks `float/begin`/`float/end` | tlb-float-hooks-001, -002-rollback |
| 0002 | (d) | bebf5fccc | `\DeclareTaggingFloatType`, generic caption names | float-017 |
| 0003 | O2 | c30a91bb1 | skip the arguments after "`\caption` outside float" | caption-outside-001 |
| 0004 | b-3a | 07b5a8817 | `\caption` reads its arguments, `\caption*`, `caption/before`, `caption/step` with the switches, `\@kernel@caption` (the interface test), `\@kernel@caption@reset`; latex-lab without its own `\caption` | caption-interface-001, -002, float-028 |
| 0005 | b-3b | 979d62f7b | unique targets for unstepped captions, `\@kernel@caption@unique` | caption-interface-003, float-024 |
| 0006 | b-3c | 05e6d4f6d | `\caption*` with a replaced `\@caption` (llncs, mwcls, threeparttable) | caption-interface-004 |
| 0007 | b-3d | a2775b254 | separator look-ahead of `\@caption@nolabel` | caption-interface-005 |
| 0008 | b-3f | 304c6fd2e | first aid: `\caption*` with float.sty | firstaid-float-caption, -hyperref |
| 0009 | b-1 | 2edb486e2 | latex-lab: float target per type (fixes the two latex-lab bugs) | float-023, float-004 |
| 0010 | b-4 | 271f6728c | `caption/prepare`, 3-argument `caption/listentry` | caption-interface-006 |
| 0011 | (c) | 5b6eb6b66 | section (c); also latex3/latex2e#2022 (empty label) | float-021, -022, -025, -026, -027, -029, -030 |
| 0012 | b-5 | d7f0671a9 | `caption/typeset`, `\@kernel@@caption` (request for comments) | caption-interface-007 |
| 0013 | b-6 | ab41c6600 | `subfloat/box` (request for comments) | float-020 |
| 0014 | announce | 449aa8e30 | usrguide section and ltnews44 draft; to apply only with hyperref support for `\caption*` | — |
| O1.patch | O1 | 5576f6bb3 | nameref title in `\@caption` (optional) | caption-interface-008 |

What is optional: b-5 and b-6 are requests for comments; O1 is optional; the last commit waits for
hyperref. b-3d is not a free choice: without it the standard classes print ": Text" for
`\caption*` (the alternative, a `classes.dtx` change, breaks babel-french and caption3). b-3b and
b-3c are needed by the float first aid for restyled floats and by the hyperref sketch (the cover
letter still calls them droppable; this is being corrected).

The series had three review rounds; the open points are in the cover letter and in
`PROPOSAL-b-v2.md`. The release date (2026/11/01 in every release block) is a placeholder.

### 5. How caption uses it

caption becomes a client if `\@kernel@@caption` is defined (from b-5 on, together with the
socket `caption/typeset` it needs); otherwise its v3.7 code runs unchanged. On the client path it restores the kernel copies at `\begin{document}` (where it used
to install its own `\caption`/`\@caption`), decides step, target and list entry in
`caption/before`, makes its hypcap anchor in `caption/prepare` (for an unstepped caption with
`\@kernel@caption@unique{<type>}{\hyper@makecurrent{<type>}}`), and plugs `caption/listentry`
and `caption/typeset`. subcaption uses `subfloat/box`. All of v1's interceptions
(`\stepcounter`, `\@dblarg`, `\if@skiphyperref`, `\@currentHref`, meaning tests, the
`\aftergroup` position transfer, the global `\linewidth`) are gone. The client path is taken in
every tested setup, including classic hyperref, float.sty and memoir. caption's test suite (310
tests): on TeX Live the failure lists equal v3.7's; on the patched kernel the only new failure
is `issue_111` (the kernel's error for `\caption` outside a float instead of caption's).

### Open questions for the team

1. Is a kernel `\caption*` with this contract welcome, with the separator removal as an
   optional layer? Would hyperref take one of the two sketches, and beamer support the star?
   Should KOMA-Script, memoir, the AMS classes and babel-french be told in advance?
2. Two hooks with four arguments: are the names `caption/before` (next to the generic
   `cmd/caption/before`) and `caption/prepare` right?
3. Step and target control: switches set in a hook (as here), plugs assigned in
   `caption/before`, or arguments of `caption/step`? Should a "refstepcounter with options" live
   in ltxref? Is the naming rule `<name>*<n>` acceptable?
4. `\@floatHref@<type>`: latex-lab state read by the kernel, or a latex-lab plug of
   `caption/step`?
5. `caption/typeset` and the copies: acceptable as a step towards a template-based caption, or
   should availability be a documented conditional and the copies not be restored by clients?
6. Sub-floats: `subfloat/box` with one-shot plugs, a key for `minipage`/`\parbox`, or a
   sub-float environment in latex-lab? Which role in table cells?
7. A first aid that adds `\caption*` to the unmaintained float.sty?
8. The names a client may use: the copies, hooks, sockets, switches, `\@floatHref@<type>`,
   `\@kernel@caption@reset` and `\@kernel@caption@unique`. Is `\@kernel@...` the right form for
   commands that packages are told to call, or should they get public names?
9. O1 in the kernel or in nameref? O2 looks uncontroversial.
10. Release: the patches use 2026/11/01, too early for an interface that has not been
    discussed. Which release, and is a latex-dev phase wanted? (A draft ltnews44 text is in
    the last commit of the series.)
