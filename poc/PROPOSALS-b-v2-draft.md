## (b) A caption interface: `\caption*`, list entries, sub-captions (version 2)

> **DRAFT, not sent.** 2026-10-06. This replaces version 1 of (b) (2026-10-04; the old text is
> in the git history of `poc/PROPOSALS.md`). The long working version with all measurements and
> review findings is `PROPOSAL-b-v2.md` in the caption branch `poc-b2` (folder `poc-b2/`).

Patches (in `poc/proposals/patches/b-v2/`):
- `series/0001-0028`: version 2 as 28 commits on top of the series (a), (d), (b) v1, (c)
  (`patches/series/0001-0004`); `kernel-b2.patch` is the same as one diff. Together they give
  latex2e branch `poc-b2` (head 37cb2bcd7) on develop 829e56a15.
- `on-develop-2a9bfe9d6/`: all 32 commits replayed on develop 2a9bfe9d6 (2026-10-06), because
  the 829e56a15 patches now conflict in `required/latex-lab/changes.txt`.
- `caption-client.diff`: caption as a client (against the caption PoC v3.8, a518ec6).

Tests (copies in `poc/proposals/tests/b-v2/`): base `caption-interface-001` (32 cases), `-002`
(roll-back), `-003` (unique names); latex-lab `float-020`, `float-023`, `float-024`; firstaid
`firstaid-float-caption`, `-hyperref`.

**Not yet a reviewable series.** Version 2 is built on version 1 and then rewrites much of it,
and its core is one large commit. The split into the parts of section 4 has started on current
develop ((a), (d), O2 are done); until it is finished, please read the patches as a prototype of
the interface, not as the PR.

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

The three `\@kernel@...` commands are defined in one release block, so a `latexrelease`
roll-back undefines them; the hooks, sockets and switches stay defined (unused), so
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
- Known gaps: `subfloat/box` needs a group around the box; O1 overwrites titles that memoir or
  nameref sanitised; `\@kernel@caption@unique` must not be used between a `\caption*` handled by
  a replaced `\@caption` and the next `\caption` (it loops); with hyperref's
  `naturalnames=true`, captions left unstepped by other code still give duplicates.
- Size: ltfloat.dtx code grows from 371 lines (develop) to 656 (all proposals with v2).

### 4. Parts (the planned PRs) and their state

| part | content | state |
|---|---|---|
| O2 | skip the arguments after "`\caption` outside float" | committed on develop 2a9bfe9d6 after (a) and (d); passes the full base suite, hook configs, firstaid, latex-lab float |
| b-3 | `\caption` reads its arguments, `\caption*` with `\@caption@nolabel`, `caption/before`, `caption/step` with the switches and unique targets, replaced-`\@caption` settings, `\@kernel@caption@reset`, `\@kernel@caption@unique`, documentation (ltfloat, usrguide and clsguide drafts) | in progress |
| b-3f | first aid: `\caption*` with float.sty | to split |
| b-1 | latex-lab: float target per type, generic structure names (needs b-3's step plug) | to split |
| b-4 | `caption/prepare`, 3-argument `caption/listentry` | to split |
| (c) | (section (c)), after b-3 | to rebase |
| b-5 | `caption/typeset`, the kernel copies | to split; open design question (RFC) |
| b-6 | `subfloat/box` | to split; open design question for the tagging team (RFC) |
| O1 | nameref title | to split, or to nameref |

The current code (v1 series + 28 commits) passes, on its head: the full base suite in pdfTeX,
XeTeX and LuaTeX (605 tests), all base configurations, firstaid, and all latex-lab CI
configurations (the same differences as develop, all local: the `<PDF>` vs
`<PDF version="2.0">` line of show-pdf-tags and similar).
Every commit of the v1 series passes the same on its own.

### 5. How caption uses it

caption becomes a client if `\@kernel@caption` is defined; otherwise its v3.7 code runs
unchanged. On the client path it restores the kernel copies at `\begin{document}` (where it used
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
    discussed. Which release, and is a latex-dev phase wanted? (No ltnews text yet.)
