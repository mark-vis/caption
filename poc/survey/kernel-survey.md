# Kernel / latex-lab survey for caption4 (2026-10-03)

Sources: latex2e develop f4c052f (2026-10-03), TL2026 format 2026-06-01 PL0, latex-lab float 0.81n
2026-04-24. [K] = stable kernel in TL2026, [LAB] = latex-lab only (tagging/testphase), [DEV] = develop only.
Verified by reading code and compiling; items marked "inferred" are not verified.

## Floats
- [K] No hooks or sockets in `\@float`, `\@xfloat`, `\end@float`, `\@floatboxreset`, `\caption`, `\@caption`,
  `\@makecaption` (base/ltfloat.dtx). The only generic entry points are `cmd/<name>/before|after` hooks
  (e.g. `cmd/@xfloat/before`, `cmd/@floatboxreset/after`).
- [K] Tagging sockets declared but unused by the kernel: `float/hmode/begin`, `float/hmode/end`, `float/begin`,
  `float/end` (lttagging.dtx:958-972; 2024-11-01).
- [LAB] latex-lab-float redefines `\@xfloat`, `\end@float`, `\end@dblfloat` and `\caption` at load time, and
  `\@makecaption` at begindocument.
  - In `\@xfloat`: `\__tag_float_init:` (sets `\@current@float@struct`), then `\UseTaggingSocket{float/begin}`,
    then the box with `\@floatboxreset`, then `\MakeLinkTarget*{\@captype.struct.\@current@float@struct}`
    inside the box (this amounts to built-in hypcap).
  - `float.sty` [H] floats go through latex-lab-firstaid `\@float@HH`/`\float@endH` with sockets
    `float/H/begin` and `float/H/end`.
- `env/<name>/begin|end` hooks exist for each environment name only; there is no generic one.

## Captions
- [K] Sockets declared but unused: `caption/begin`{1}, `caption/end`, `caption/label/begin`,
  `caption/label/end` (lttagging.dtx:979-1004, 2024-09-17).
- [LAB]
  - `\NewSocket{caption/label}{1}` (plug kernel = `#1:~`; TODO: "revisit after checking float and caption
    packages").
  - `\NewHookWithArguments{cmd/@makecaption/before}{2}`.
  - `\caption` inside a float: `\@kernel@refstepcounter\@captype`, `\@currentHref` = `<type>.struct.<n>`.
  - `\@makecaption`: measures with `\SuspendTagging`, then opens a `Caption` structure (parent float struct,
    firstkid), with the label in `Lbl`.
  - Floats become Aside, deferred into a Sect at the end of the document. Keys: `float/flush`, `float/defer`,
    `float/here`, `float/split`.
- [LAB] There is NO caption-package compatibility code. hyperref is told not to patch captions when
  DocumentMetadata is used (hyperref.sty:109-121, format ≥ 2025-11-01).
- Caption settings are lost under tagging because caption.sty sets `\@makecaption` at load time and
  latex-lab overwrites it at begindocument. Verified: `labelsep=period`, `justification=raggedleft` ignored
  for the main caption; subcaptions keep their settings (they bypass `\@makecaption`).
- latex-lab-table patches `\LT@makecaption`: "The caption package will quite probably break the longtable
  caption".
- [DEV]/plan: captions via the template mechanism and contexts (ltnews43; latex-lab-context TODOs).

## Subfigures
- [LAB] latex-lab-float.dtx:99-100: "Subfigures and subcaptions are currently not handled, but will be
  implemented as simple `Part` with their own `Caption`."
- Under tagging now: subcaptions are not tagged as Caption; subfigure minipages become Div.
- subcaption + hyperref + `\listoffigures` under tagging: warning "Destination 'figure.caption.2' has no
  related structure" (tagging-project issue #85), because caption uses its own anchor instead of
  `figure.struct.N`.

## Labels, properties, targets [K]
- `label` hook (2023-06-01): `\NewHookWithArguments{label}{1}`, runs inside `\label` before the write.
- `refstepcounter` sockets (2024-11-01); `\@kernel@refstepcounter`; `\theH<counter>` auto-defined (2024-09).
- Properties (2023-11-01): `\NewProperty`, `\RecordProperties{label}{props}`, `\RefProperty[default]{label}{prop}`
  (expandable), `\IfPropertyRecordedTF`, …; predeclared label, page, abspage, title, target, pagetarget, counter,
  xpos, ypos. They are stored in `\r@<label>`, so the label names must not collide with real `\label`s.
- `\MakeLinkTarget` (2022-06-01 dummy; 2024-11-01 sets `\@currentHref`); hyperref redefines it to create anchors.

## Tagging status (TL2026 latex-tagging-status.ltx; notes from the tagging-project yml)
- caption: currently-incompatible. "the configurations from the package are overwritten by the tagging code.
  Issue when hyperref and both listoffigures are used." Issues #84, #720.
- subcaption: currently-incompatible. Issue #85.
- ltcaption: currently-incompatible. #256.
- subfig, bicaption, newfloat, float: currently-incompatible.
- floatrow: no-support.

## Other kernel interfaces
- `\DeclareKeys`/`\SetKeys`/`\ProcessKeyOptions`: 2022-06-01.
- hooks: 2020-10-01; generic cmd hooks: 2021-06-01; hooks with arguments: 2023-06-01.
- sockets: 2023-11-01; `\NewTaggingSocket`/`\SuspendTagging`: 2024-06-01.
- `\IfPackageAtLeastTF`: 2020-10-01; templates: 2024-06-01.
