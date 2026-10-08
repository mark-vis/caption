# Caption hooks and sockets: the patch series

14 commits on latex2e develop **e58563c7c** (2026-10-08). The patches are in `series/`
(`git format-patch`); the same commits are on branch `b2-split` of
https://github.com/mark-vis/latex2e (head **46a994237**). Not yet a pull request.

```sh
git checkout -b b2-split e58563c7c
git am /path/to/series/*.patch       # gives the tree of every commit, head 46a994237
```

Two separate files: `O1.patch` (optional, applies on top of the head) and
`O2-standalone.patch` (the fix for `\caption` outside a float alone on develop e58563c7c, with
its own `.tlg` files, if a small first step is wanted).

The commit subjects are plain; the short labels ((a), (d), O2, b-3a ...; b-2 and b-3e were folded into other parts) are only used in this
letter and in `poc/PROPOSALS.md`. Each commit message describes the change, its tests and its
open questions in full.

| label | commit | subject |
|---|---|---|
| (a) | 220798b8e | Add hooks float/begin and float/end |
| (d) | 2111e4cfd | Add \DeclareTaggingFloatType and generic caption names |
| O2 | 8505bc5ed | Skip the arguments of \caption outside a float |
| b-3a | 5c42c5d86 | Add \caption*, hook caption/before and socket caption/step |
| b-3b | 6603b90d0 | Give captions that do not step their counter a unique target |
| b-3c | 00755265e | Support \caption* with an \@caption that a class replaced |
| b-3d | 9fbf5cc8d | Remove the usual separator after the label of \caption* |
| b-3f | 19bf2fbd3 | firstaid: \caption* with the float package |
| b-1 | 117a9dcef | latex-lab: float target \@floatHref@<type> |
| b-4 | 37fccd426 | Add hook caption/prepare and socket caption/listentry |
| (c) | 312873213 | latex-lab: label contract, caption/separator, in-paragraph labels |
| b-5 | 0e2a124c0 | Add socket caption/typeset and the kernel copy \@kernel@@caption (request for comments) |
| b-6 | c2c39c88b | Add tagging sockets for sub-floats (request for comments) |
| announce | 46a994237 | Document \caption* in usrguide; draft LaTeX News entries |
| O1 (`O1.patch`, optional) | da2602471 | Set \@currentlabelname for captions (title for named references) |
| O2 alone (`O2-standalone.patch`) | 0507c6fc6 | Skip the arguments of \caption outside a float |

## Order and dependencies

- (a), (d) and O2 are independent of each other. (d) applies alone to develop (only
  `changes.txt` needs a merge). O2 in the series is on top of (a); on its own, use
  `O2-standalone.patch`, which passes the full test set on develop.
- b-3a is the core. It also defines `\@kernel@caption` (a copy of `\caption`, and the test for
  the interface) and `\@kernel@caption@reset`; both are undefined after a roll-back. Code that
  keeps its own `\caption` (the float first aid of b-3f, a future hyperref) passes `\caption*` to
  `\@kernel@caption*` and starts its numbered caption with `\@kernel@caption@reset`.
- b-3b (unique targets) and b-3c (a replaced `\@caption`) are **not** optional. b-3c needs
  b-3b. The float first aid (b-3f) lets float's caption code act as a replaced `\@caption` in
  restyled floats, so without b-3c `\caption*{Starred}` in a ruled algorithm gives
  "Algorithm 1 Starred" with a list entry. The hyperref change asked for below needs b-3b and
  b-3c, because classic hyperref replaces `\@caption` too. The caption client needs
  `\@kernel@caption@unique` from b-3b.
- b-3d (the separator look-ahead) is not a free choice either. Without it article, report and
  book print ": Text" for `\caption*` (with tagging: "Text"), llncs, IEEEtran and mwart print
  their separator, and the float first aid gives ": Text" for float's plain style. The
  alternative, a `classes.dtx` change, breaks babel-french's separator and caption3's class
  detection (both compare `\@makecaption` with `\STD@makecaption`); see the commit message.
- So b-3a to b-3d are one unit for a `\caption*` that works with the standard classes, float.sty
  and hyperref. A smaller first step would be b-3a + b-3d (standard classes, tagging) without
  float.sty and hyperref support; b-3f then waits as well.
- b-5 and b-6 are requests for comments; their messages list the questions.
- Can be left out: b-3f as a whole (then `\caption*` with float.sty gives the output of
  develop), b-4 to b-6, (c) and b-1 (if the team takes them on develop instead), and the
  announce commit (a possible usrguide section and LaTeX News text, if wanted; it assumes
  hyperref support for `\caption*`).

The caption package (`caption-client.diff`; branch `poc-b2` of
https://github.com/mark-vis/caption) takes its client path only when `\@kernel@@caption` is
defined, i.e. from b-5 on; on earlier kernels it runs its own code unchanged.

Related issues: latex3/latex2e#2022 (empty caption label in a wide caption: fixed in (c)),
latex3/tagging-project#450 and #890 (newfloat and float with tagging: (d) gives their captions
and labels generic names, but their float environments still fail under tagging, as on
develop), #1487 (several captions in one float: b-1's target after `float/split`).

## Tests

Run with `l3build check` on a `git archive` export of each commit:

- every commit of the series, O1 and O2 alone: the base suite in pdfTeX, XeTeX and LuaTeX,
  `config-lthooks`, `config-lthooks2`, the other base configurations (1run, TU, doc, legacy,
  ltcmd, ltmarks, lttemplates), firstaid (`build`, `config-TU`) and latex-lab `config-float`:
  all pass, except that `config-float` shows the `<PDF>` line (below) and nothing else:

  | commits | `config-float` `.diff` files |
  |---|---|
  | (a); O2 alone | 2 (as develop) |
  | (d), O2 | 4 (+ float-017) |
  | b-3a to b-3f | 6 (+ float-028) |
  | b-1, b-4 | 8 (+ float-023) |
  | (c), b-5 | 18 (+ float-021/022/027/029/030) |
  | b-6, announce, O1 | 20 (+ float-020) |

- all 18 latex-lab CI configurations and `required/tools` on the head: tools and
  `config-minipage` pass; the 53 `.diff` files that develop e58563c7c also has show the same
  lines; the 18 new ones are only `config-float` files with the `<PDF>` line (on the earlier
  develop 2a9bfe9d6 the same held for b-3a, b-3f, b-6 and O1);
- on the head: `config-doc` passes, and usrguide, clsguide and ltnews44 typeset without errors
  (on develop 2a9bfe9d6 also `l3build doc`, all 8 CI documentation jobs).

About `<PDF version="2.0">`: the `.tlg` files in the repository contain `<PDF version="2.0">`,
the show-pdf-tags of my TeX installation writes `<PDF>`. So `firstaid-float-H-2`,
`firstaid-listings` and (LuaTeX) `table-015-hhline` fail in my runs on develop too, and the new tests that print the structure
differ in that one line. Their `.tlg` files may need to be saved again on your setup.

With documents: the caption client (`caption-client.diff`) with a class matrix (249 documents,
pdfLaTeX and LuaLaTeX), 318 further test documents and a corpus of 78 jobs. On the b-4 kernel the
client takes its own code path, with the same 65 documents with `!` lines as on the head (`\show`
probes, setup errors of third-party classes, roll-back cases); from b-5 on it takes its client
path. hyperref sketch A (below) with 20 documents works on the b-3f kernel and on the head; on
b-3a alone it gives "Figure 1: Starred" with a list entry and a duplicate destination.

Not run: caption's own `test.sh` on this exact series, PDF/UA validation, XeTeX documents
outside l3build, a roll-forward from an older format (develop's own roll-forward from the
TL 2026 format is broken in my tests), the latex-lab CI configurations on the other intermediate commits,
the class matrix and the corpus on the intermediate kernels, LuaLaTeX for the intermediate-kernel
client runs and for the hyperref sketch.

## Open questions

- **hyperref.** Classic hyperref (without `\DocumentMetadata`) replaces `\caption`, so
  `\caption*` still gives "Figure 1: * Text" there, as on develop. The series asks hyperref for
  one change ("sketch A"): when `\@kernel@caption` is defined, keep its `\caption` for numbered
  captions, pass only the star to `\@kernel@caption*`, and start each numbered caption with
  `\@kernel@caption@reset`. It needs b-3a to b-3d, not b-5. The alternative, sketch B (hyperref
  skips its caption patches, `\hyper@nopatch@caption`), is not proposed: it gives duplicate
  destinations with mwart, and the nameref title would then have to come from the kernel (O1).
  A hyperref patch that uses `caption/prepare` for its anchor was not written.
- **Release date.** All `\IncludeInRelease` blocks use `2026/11/01` as a placeholder (the date
  develop uses for its next release); `\changes`, file dates and `changes.txt` use 2026-10-06.
  For a later release the 8 blocks in `ltfloat.dtx` change. The blocks are "caption arguments"
  (`\caption`), "caption body" (`\@caption`), "caption interface" (`\@kernel@caption@step`) and
  "caption interface copies" (`\@kernel@caption`, `\@kernel@caption@unique`,
  `\@kernel@@caption`).
- **Names.** Is `\@kernel@...` the right form for commands that packages are told to call
  (`\@kernel@caption`, `\@kernel@@caption`, `\@kernel@caption@reset`,
  `\@kernel@caption@unique`), or should they get public names? The same for the hooks, sockets,
  switches and `\@floatHref@<type>`.
- **O1** sets `\@currentlabelname` from the raw list text. It is not in the series because the
  title is not sanitised and it overwrites the cleaned title that memoir and nameref set. Kernel
  or nameref?
- The questions of b-5 (whether the copy `\@kernel@@caption` is wanted) and b-6 (whether
  sub-floats belong in the interface, the role Part, `subfloat/box` or only begin/end) are in
  their commit messages; the full list is in `poc/PROPOSALS.md`, section (b).
