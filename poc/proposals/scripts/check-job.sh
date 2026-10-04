#!/bin/sh
# check-job.sh TREE JOB   -- run one l3build job in a latex2e tree (copy per job:
# l3build jobs in one tree share base/build and must not overlap).
# JOB: base | lthooks | float | table-pdftex | table-luatex | block
T=$1; J=$2
BASETESTS="tlb-float-hooks-001 tlb-float-hooks-002-rollback caption-interface-001
 tlb0002a tlb-fltrace-000 tlb-hfloat-01 tlb0018 tlb1893 tlb2400 tlb2815 tltx001 tl2e8
 github-robust-0123
 tlb-latexrelease-rollback-001 tlb-latexrelease-rollback-002
 tlb-latexrelease-rollback-003-often tlb-latexrelease-rollback-004
 tlb-latexrelease-rollback-2025-11-01 tlb-latexrelease-rollback-2026-06-01
 tlb-latexrelease-rollback-2026-11-01"
lim() { t=$1; shift; perl -e 'alarm shift; exec @ARGV' -- "$t" "$@"; }
case $J in
  base)         cd "$T/base" && lim 3000 l3build check -e pdftex,luatex $BASETESTS ;;
  lthooks)      cd "$T/base" && lim 3000 l3build check -c config-lthooks ;;
  float)        cd "$T/required/latex-lab" && lim 3000 l3build check -c config-float ;;
  table-pdftex) cd "$T/required/latex-lab" && lim 3000 l3build check -c config-table-pdftex ;;
  table-luatex) cd "$T/required/latex-lab" && lim 3000 l3build check -c config-table-luatex ;;
  block)        cd "$T/required/latex-lab" && lim 1200 l3build check -c config-block firstaid-listings ;;
esac
