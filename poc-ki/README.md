# PoC: caption on the proposed kernel interfaces (a)-(d)

DRAFT, 2026-10-05. Branch `poc-kernel-interfaces` = caption v3.7 + changes that make caption
(v3.8 PoC), caption3 (v2.6 PoC) and subcaption (v1.8 PoC) use the kernel interfaces proposed in
`poc/PROPOSALS.md` (branch `poc-caption4`), when they exist.

- `RESULTS.md`: what was measured, results, and the gaps in the proposals (section 6, G1-G7).
- `README-POC.md`: the test setup used (paths refer to a scratch directory).
- `kernel-patches/`: latex2e patch series (apply with `git am` to latex2e develop 829e56a15)
  and newfloat v1.2a.
- `corpus/`: test documents and the driver scripts (`run.sh`, `compare.sh`).

To rebuild the patched kernel: in a latex2e clone at 829e56a15, `git am kernel-patches/000*.patch`,
then `l3build check tlb-float-hooks-001` in `base/` (builds the formats in `build/test/`) and
`l3build unpack` in `required/latex-lab` and `required/tools`; put `build/unpacked` and the
repository's `texmf/tex` on TEXINPUTS.
