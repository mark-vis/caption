> **Copy for `poc/proposals/patches/b-v2/` (2026-10-08).** The cover letter of the series as
> written in the PoC environment (`poc-env/b2-revision/scripts/r5/split2/COVER.md`). Paths such
> as `series-r3text/`, `logs/...`, `repair2/logs/...` and `split2/meta/...` are relative to that
> folder; here the patches of `series-r3text/` are in `series/`, next to `O1.patch` and
> `O2-standalone.patch`. This version includes the text fixes of review round 6.3 (R63-M1, L1, L2):
> only commit messages and one usrguide source comment changed.

# Caption hooks and sockets: the patch series

Local branch `b2-split` of the latex2e clone: 14 commits on develop **2a9bfe9d6** (2026-10-06),
head **dd54d64b9**. Not pushed and not posted. The patches are in `series-r3text/` (git format-patch);
`git am series-r3text/*.patch` on 2a9bfe9d6 gives the tree of every commit
(`logs/series-r3text-am-check.txt`).

Text revision after review round 6.3 (2026-10-08; the previous head 449aa8e30 is kept as
`b2-split-r3textbackup`, its export in `series/`): only commit messages changed, plus one source
comment in `usrguide.tex` in the last commit. The trees of commits 1-13 are identical to those of
round 6.3; the last commit differs only in that comment (`logs/series-r3text-hashmap.txt`).
Per-commit CI after the text revision (`poc-env/ci/results/dd54d64b98fb.txt`): std PASS on all 14
(commits 1-13 from the tree cache), lab PASS on the head.
Changes: the dependencies of b-3b/b-3c are stated (b-3f and the hyperref route need them; R63-M1),
the series asks hyperref for one change (sketch A; R63-L1), and the messages no longer refer to
earlier versions of the proposal or to "the series" (R63-L2).
Separate files: `O1.patch` (optional, on top of the head) and `O2-standalone.patch` (the `\caption`
outside-a-float fix alone on develop, with its own `.tlg` files).

The commit subjects are plain; the short labels below ((a), (d), O2, b-3a ...) are only used in this
letter and in the proposal documents. The caption package (branch `poc-b2`, f5b2370, local) is the
client. It takes its client path only when `\@kernel@@caption` is defined (from b-5 on, together
with the socket `caption/typeset` it needs); on the earlier kernels it falls back to its own code.

| label | commit | subject |
|---|---|---|
| (a) | 2e1246c7c | Add hooks float/begin and float/end |
| (d) | bebf5fccc | Add \DeclareTaggingFloatType and generic caption names |
| O2 | 28bd304c8 | Skip the arguments of \caption outside a float |
| b-3a | 721622eec | Add \caption*, hook caption/before and socket caption/step |
| b-3b | aff8c2a32 | Give captions that do not step their counter a unique target |
| b-3c | 2e60929aa | Support \caption* with an \@caption that a class replaced |
| b-3d | a65bb571f | Remove the usual separator after the label of \caption* |
| b-3f | 3bfd34630 | firstaid: \caption* with the float package |
| b-1 | 40458f577 | latex-lab: float target \@floatHref@<type> |
| b-4 | 413a65cd4 | Add hook caption/prepare and socket caption/listentry |
| (c) | ef48558d2 | latex-lab: label contract, caption/separator, in-paragraph labels |
| b-5 | ebac3521e | Add socket caption/typeset and the kernel copy \@kernel@@caption |
| b-6 | 8f83a89b2 | Add tagging sockets for sub-floats |
| announce | dd54d64b9 | Document \caption* in usrguide; draft LaTeX News entries |
| O1 (optional, O1.patch; branch on the old head, the patch applies unchanged on the new one) | 5576f6bb3 | Set \@currentlabelname for captions (title for named references) |
| O2 alone (O2-standalone.patch) | 98c6642b6 | Skip the arguments of \caption outside a float |

Order and what can be dropped:
- (a), (d) and O2 are independent of each other in their code. (d) applies alone to develop (only
  `changes.txt` needs a merge). O2 as committed here was generated on top of (a); for a first PR use
  `O2-standalone.patch`, which has its own `.tlg` files and passes the full test set on develop.
- b-3a is the core. It also defines `\@kernel@caption` (a copy of `\caption`), the test for the
  interface: like `\@kernel@caption@reset` it is undefined after a roll-back. Code that keeps its
  own `\caption` (the float first aid of b-3f, a future hyperref) passes `\caption*` to
  `\@kernel@caption*` and starts its numbered caption with `\@kernel@caption@reset`; none of this
  depends on the request-for-comments parts b-5 and b-6 (but see b-3c/b-3d for a replaced
  `\@caption` and the separator).
- b-3b (unique targets) and b-3c (a replaced `\@caption`) are **not** optional. No later part calls
  b-3c's macros, but later parts rely on their effect: b-3c needs b-3b (`\@caption@uniqueH`); the
  float first aid (b-3f) lets float's caption code act as a replaced `\@caption` in restyled floats
  (`algorithm.sty`, every `\newfloat` and `\restylefloat` type), so without b-3c `\caption*{Starred}`
  in a ruled algorithm gives "Algorithm 1 Starred" (the previous number) with a list entry; hyperref
  sketch A (below) needs b-3b and b-3c, because classic hyperref replaces `\@caption` too (without
  b-3c: "Figure 1: Starred", a list entry and a duplicate destination); and the caption client needs
  `\@kernel@caption@unique` from b-3b. So b-3a to b-3d are one unit for a `\caption*` that works with
  the standard classes, float.sty and hyperref. A smaller first step would be b-3a + b-3d (standard
  classes, tagging) without float.sty and hyperref support; then b-3f must wait as well.
- b-3d (the separator look-ahead) is **not** a free choice. Without it every class that does not
  test `\if@captionstar` prints its separator before the text of `\caption*`: the standard classes
  article, report and book give ": Text" (while the same document with
  `\DocumentMetadata{tagging=on}` gives "Text", because latex-lab's `\@makecaption` tests the
  switch), llncs, IEEEtran and mwart give their separator, and the float first aid (b-3f) gives
  ": Text" for float's plain style. The alternative is that `classes.dtx` tests the switch. Its cost:
  babel-french installs its French separator only if `\@makecaption` is
  `\STD@makecaption`, and caption3 recognises the standard classes by the same comparison, so any
  change to the standard `\@makecaption` gives "Figure 1: text" instead of "Figure 1 -- text" in
  French pdfLaTeX documents (caption's test/babel/french-0, -4, -5) and an "unknown class" in
  caption. So the choice is between b-3d and a `classes.dtx` change together with babel-french and
  caption; b-3d's commit message says this.
- b-5 and b-6 are requests for comments; their messages list the questions. b-5 now holds only
  the socket `caption/typeset` and the copy `\@kernel@@caption` of `\@caption`.
- The last commit (usrguide section and LaTeX News draft) is meant to be applied only when hyperref
  supports `\caption*` (see below).
- What can really be left out: b-3f as a whole (then `\caption*` with float.sty keeps the output of
  develop), b-4 to b-6, (c) and b-1 if the team takes them on develop instead, and the announce
  commit. b-3a to b-3d cannot be split further without the costs named above.

Release date (PLACEHOLDER): all `\IncludeInRelease` blocks use `2026/11/01`, the date develop already
uses for its next release. `\changes` entries, file dates and `changes.txt` use 2026-10-06 (the
hyphen form develop's ltfloat uses). For a later release run
`split2/meta/set-release-date.sh <tree> YYYY/MM/DD` (it changes the 8 blocks in `ltfloat.dtx`). The
release blocks keep the names they get when they are created, all of them from b-3a on except
"caption arguments" (O2): "caption arguments" for `\caption`, "caption body" for `\@caption`,
"caption interface" (`\@kernel@caption@step`: hook `caption/before`, socket `caption/step`) and
"caption interface copies" (`\@kernel@caption`; b-3b adds `\@kernel@caption@unique`, b-5
`\@kernel@@caption`), so the roll-back `.tlg` files change only when a block is added.

Related issues: latex3/latex2e#2022 (empty caption label in a wide caption: fixed in (c), and the
reason for the `nolabel` plugs of b-3a), latex3/tagging-project#450 and #890 (newfloat and float
with tagging: (d) gives their captions and labels generic names, but their float environments still
fail under tagging, as on develop), #1487 (several captions in one float: b-1's target after
`float/split`).

hyperref: classic hyperref (without `\DocumentMetadata`) replaces `\caption`, so `\caption*` still
gives "Figure 1: * Text" there, as on develop. O2 does not change hyperref's or float.sty's own
`\caption` outside a float either. Two hyperref sketches were tested in the proposal rounds
(PROPOSAL-b-v2.md 2.6.5). The series asks hyperref for one change, sketch A: when
`\@kernel@caption` is defined, hyperref keeps its `\caption` for numbered captions, sends only the
star to `\@kernel@caption*` and starts its numbered `\caption` with `\@kernel@caption@reset` (the
announce commit's message and the usrguide source comment say the same). Sketch A does not need b-5,
but it needs b-3a to b-3d: classic hyperref also replaces `\@caption`, which b-3c handles (with the
unique names of b-3b), and b-3d removes the separator. The alternative, sketch B (hyperref skips its
caption patches, `\hyper@nopatch@caption`), is not proposed: it gives mwart 2 duplicate destinations
for numbered captions, and the nameref title of a caption would then have to come from the kernel
(O1, which is not in the series). Rerun (`repair2/logs/hyp-sketchA.txt`): on the b-3f
kernel and on the new head all 20 documents are identical to the previous head; on the b-3a kernel
alone the 10 sketch documents give "Figure 1: Starred" with a list entry and a duplicate
destination (the 10 without the sketch are unchanged).
A hyperref patch that uses `caption/prepare` (b-4) for its anchor and the nameref title was not
written.

## (a) Add hooks float/begin and float/end
Two mirrored hooks with two arguments (type, `*` for a double-column float in two-column mode), run
inside the float box (`\@xfloat`, `\@xdblfloat`, `\@endfloatbox`). latex-lab-float runs
`float/begin` after its float target. Tests: `tlb-float-hooks-001`, `-002-rollback`.

## (d) Add \DeclareTaggingFloatType and generic caption names
`\DeclareTaggingFloatType{<type>}` in lttagging; the list of float types moves there; captions and
labels in floats of undeclared types use `float/generic/caption|label`. Before, `\UseStructureName`
gave an undefined control sequence for the captions of such floats. It does not make float
environments of newfloat/float.sty work under tagging (those still give the errors of develop at
`\begin{<type>}`). Test: latex-lab `float-017-declare`.

## O2 Skip the arguments of \caption outside a float
After the error "\caption outside float" the star and both arguments are skipped (before, the text was
typeset). Packages with their own `\caption` (latex-lab until b-3a, hyperref, float.sty) are not
changed. Test: `caption-outside-001`.

## b-3a Add \caption*, hook caption/before and socket caption/step
`\caption` reads its star and arguments itself (no `\@dblarg`), runs the hook `caption/before
{type}{star}{opt}{text}` and steps through the socket `caption/step` (switches `\if@captionstep`,
`\if@captiontarget`). `\caption*`: no step, no target, no list entry, label `\@caption@nolabel`
(prints nothing) with `\if@captionstar` true. A caption that does not step uses the float target or
makes no target. Interim `\@caption` (block "caption body"). `\@kernel@caption`, the copy of
`\caption` and the interface test (block "caption interface copies"). latex-lab: no `\caption`
redefinition, an interim `caption/step` plug (only for the counter of the float type), `\caption*`
in `\@makecaption` with the `nolabel` plugs. With this commit alone the standard classes print
": Text" for `\caption*` (b-3d removes the separator). Tests: `caption-interface-001` (14 TESTs),
`-002` (roll-back), latex-lab `float-028`.

## b-3b Give captions that do not step their counter a unique target
`figure.1*1`, `figure.1*2`, ... instead of no target; `\@kernel@caption@unique{<counter>}{<code>}`
(the caption client uses it). Tests: `caption-interface-003`, latex-lab `float-024` (real hyperref
plugs, no duplicate destinations).

## b-3c Support \caption* with an \@caption that a class replaced
For llncs, mwcls, jpsj2, threeparttable ...: `\fnum@<type>`, `\ext@<type>`, `\theH<type>` set for
`\caption*` until the next `\caption` or the end of the group; `\@kernel@caption@reset` ends this.
`\if@captionstar` also stays true until then (the message names this trade-off).
Needs b-3b; needed by b-3f (restyled floats) and hyperref sketch A (see "Order" above; review 6.3
`crit6-3/mwe/alg.tex`: without b-3c a ruled `algorithm` gives "Algorithm 1 Starred" with a list entry).
Test: `caption-interface-004`; float-024 gets a class `\@caption` with its own target.

## b-3d Remove the usual separator after the label of \caption*
The look-ahead of `\@caption@nolabel` (colon or period and the space after it, also after a group or
`\textbf`; a warning once for other material). What dropping it means: see above. Test:
`caption-interface-005` (its first TEST now passes the text with `\ignorespaces`, as `\@caption`
does, so the article layout is recorded as "Text" without a warning).

## b-3f firstaid: \caption* with the float package
float.sty's `\caption` does not know the star; the first aid lets `\caption*` use `\@kernel@caption*`
(test `\ifdefined\@kernel@caption`) and keeps restyled floats in their style. Relies on b-3c for
restyled floats (float's caption code is a replaced `\@caption`) and on b-3d for float's plain style. Tests: firstaid `firstaid-float-caption`, `-hyperref`.

## b-1 latex-lab: float target \@floatHref@<type>
Fixes two develop bugs in tagged floats (the caption after `float/split`, a table caption in a figure
referred to targets that are never made) and removes the interim plug. Tests: latex-lab `float-023`,
`float-004`.

## b-4 Add hook caption/prepare and socket caption/listentry
Test: `caption-interface-006`.

## (c) latex-lab: label contract, caption/separator, in-paragraph labels
The documented contract of `caption/label` (used more than once: for measuring, for the empty-label
test and for typesetting), the socket `caption/separator`, the label tagging sockets inside the
caption paragraph (as the caption package uses them), decided by the structure (the current
structure is not the one made by `caption/begin`), and an empty label (plug `noop` of
`caption/label`) with the `nolabel` plugs too (latex3/latex2e#2022).
Tests: latex-lab `float-021`, `-022`, `-025`, `-026`, `-027`, `-029` (class `\@makecaption` in a
box) and `-030` (#2022).

## b-5 Add socket caption/typeset and the kernel copy \@kernel@@caption (request for comments)
Test: `caption-interface-007`. With this commit the caption package takes its client path.
The float first aid is no longer changed here (it uses `\@kernel@caption` from b-3f on), so the
17 lthooks dumps change only once, in b-3f.

## b-6 Add tagging sockets for sub-floats (request for comments)
`subfloat/box` acts on the next box only, also when several minipages follow in the same group, and
needs no group: for a `\parbox` (whose socket plug runs at the caller's group level) the plug now
saves `\@current@float@struct`, the float target and the `parbox/after` plug and restores them
after the box (review2 G4-F1/M1: before, a `\caption` after an ungrouped `\parbox` sub-float became
a kid of the sub-float and made its own target). Test: latex-lab `float-020` (with a new figure for
this case, including a normal and a nested `\parbox` sub-float inside the sub-float).

## announce Document \caption* in usrguide; draft LaTeX News entries
The usrguide section "Captions without a number" (shortened; no list of third-party packages) and
draft ltnews44 entries for all parts (`\@kernel@caption` is no longer listed under the requests for
comments). Apply only together with hyperref support for `\caption*`.

## O1 (optional, `O1.patch`) Set \@currentlabelname for captions
`\@caption` stores the raw list text in `\@currentlabelname` (title for `\nameref`); `\caption*`
keeps the previous value, as it keeps `\@currentlabel`. Not in the series: the title is not
sanitised (in every setup), and memoir/nameref set a cleaned title before the kernel `\@caption`
that this overwrites. Tests: new base `caption-interface-008`; title fields in
float-002/003/004/007/tagging-off/023/024, firstaid-cleveref-1684.

## Test results
`repair2/l3all.sh <rev> <tag> cfg` (git-archive export, `bin/slot l3build check`) on every commit that
changed in repair round 2 (b-3a to announce, O1, O2 alone; (a), (d) and O2 are unchanged in their
trees, O2 only got a new message): the base suite in 6 shards × pdfTeX/XeTeX/LuaTeX, config-lthooks
and config-lthooks2, the 7 other base configs (1run, TU, doc, legacy, ltcmd, ltmarks, lttemplates),
the firstaid build and config-TU, and latex-lab config-float. Logs: `repair2/logs/<tag>/SUMMARY.txt`,
overview `repair2/logs/l3all-overview.txt`; (a), (d), O2: `repair1/logs/` and review2/g0.

| label | all l3build parts | config-float `.diff` files (0 lines other than the local `<PDF>`) |
|---|---|---|
| (a) | pass (repair1) | 2 (firstaid-float-H-2, as develop) |
| (d), O2 | pass (repair1; O2 tree unchanged) | 4 (+ float-017) |
| b-3a, b-3b, b-3c, b-3d, b-3f | pass | 6 (+ float-028) |
| b-1, b-4 | pass | 8 (+ float-023) |
| (c), b-5 | pass | 18 (+ float-021/022/027/029/030) |
| b-6, announce, O1 | pass | 20 (+ float-020) |
| O2 alone (on develop) | pass | 2 (as develop) |

All 18 latex-lab CI configs + required/tools (`laball.sh`) on b-3a, b-3f, b-6, announce and O1 (`repair2/logs/lab-<tag>/`,
`cmp-dev.txt` against develop 2a9bfe9d6, overview `repair2/logs/laball-overview.txt`): tools and
config-minipage pass; the 52 `.diff` files develop also has show the same lines; the new ones are
only config-float files with 0 lines other than `<PDF>`; none is gone.

CI documentation job (`l3build doc`: base components 1, 2, 5, firstaid, latex-lab 1-4) on the head:
all 8 jobs rc 0 (`repair2/logs/doc-ann/`).

`git am series/*.patch` on 2a9bfe9d6 gives the tree of each of the 14 commits; `O1.patch` on top gives
the `b2-split-o1` tree; `O2-standalone.patch` on develop gives the `b2-split-o2alone` tree
(`repair2/logs/series-am-check.txt`). Code (non-comment lines of ltfloat, latex-lab-float, the first
aid, lttagging, latex-lab-minipage, classes) of the head against the previous head 930319175: only
the first argument of the "caption interface copies" block (now `\@kernel@caption`), the order of the
three `\let` lines in it, and the `\parbox` save/restore of b-6 (`repair2/logs/code-prev-head.txt`;
against b2-split-ref: `code-ref-head.txt`).

Client (caption.sty `poc-b2` f5b2370 = `sty-split`, which tests `\@kernel@@caption`) on the rebuilt
`kernel-split` (code of the head) against the previous kernel-split (930319175) with `sty-b2-r5`:
class matrix 249 documents × 2 engines identical in every document; the review's 233 + 85 own
documents identical; corpus 78 jobs identical (`repair2/logs/cmp-*`). On the b-4 kernel (where
`\@kernel@caption` now exists but `caption/typeset` does not), the new client takes its non-client
path and gives the same error counts as the old b-4 kernel (65 documents with `!` lines, as many as on
the head: `\show` probes, setup errors of third-party classes, roll-back cases); the old client `sty-b2-r5` would take its client path
there in 76 documents and give errors in 127 (`repair2/logs/cmp-inter.txt`), which is why the
client was changed. On the b-5 kernel the new client takes its client path; against the head only
3 documents differ, all in sub-float code of b-6 (two probe dumps of the socket list, the
structure of one tagged subcaption document).

Fixes checked with documents (`repair2/logs/m1-probes.txt`, `hyp-sketchA.txt`, `repair2/mwe/`):
- M1/G4-F1: the review documents (pbx.tex, r2-sib-pbleak-tag/-taghyp.tex, sub.tex), pdfLaTeX
  and LuaLaTeX: after an ungrouped `\parbox` sub-float `\@current@float@struct` and the float target
  are the float's again, the main caption is a kid of the float (before: of the sub-float's Part)
  and `\label` after it points to `figure.struct.N` (before: `figure.2`); the ungrouped figure now
  has the same structure, targets and word positions as the grouped one; a `\parbox` sub-float in
  an undeclared float type (widget) gets the float target as well. 0 errors on both kernels.
- R62-M1: on the b-3a kernel article gives ": Starred text" (tagged: "Starred text"), float's plain
  style "Table 1 *"; with b-3d (b-3f kernel, head) "Starred text"/"Starred plain"; the head with the
  look-ahead off gives ": Starred text" and ": Starred plain" again.
- R62-M2: hyperref sketch A on the b-3f kernel = head = previous head (20 documents); on b-3a alone
  it does not yet work (see the hyperref paragraph).

Not run: caption's `test.sh`, PDF/UA validation, XeTeX documents outside l3build, a roll-forward
from an older format (develop's own roll-forward from the TL 2026 format is broken, review2);
laball on the intermediate commits other than b-3a, b-3f, b-6, announce and O1; the class matrix and the corpus on the
intermediate kernels (only the review's own documents, with pdfLaTeX, on b-4 and b-5); lualatex
for the intermediate-kernel client runs and for sketch A.
