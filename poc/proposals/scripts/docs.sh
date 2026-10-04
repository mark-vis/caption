#!/bin/sh
# docs.sh FMT TREE CAPSTOCK CAPHOOK NF12A MWE OUT
#   FMT      directory with pdftex/ and luatex/ subdirectories, each holding a
#            format and the unpacked files built by l3build (see README)
#   TREE     the latex2e tree the format was built from (for its texmf/)
#   CAPSTOCK caption .sty files (fixes-combined, v3.6p)
#   CAPHOOK  the same with caption-floathooks.diff applied (proposal a)
#   NF12A    newfloat.sty v1.2a (proposal d)
#   MWE      the directory with the .tex/.sty test documents
#   OUT      output directory
# Compiles the client documents of the four proposals and writes one summary
# line per run, plus .txt/.aux/.lof/.struct files for comparisons.
FMT=$1; TREE=$2; CS=$3; CH=$4; NF=$5; MWE=$6; OUT=$7
mkdir -p "$OUT"; cd "$OUT" || exit 1
cp "$MWE"/*.tex "$MWE"/*.sty . 2>/dev/null
NONE=/nonexistent
# tex ENGINE EXTRA-INPUTS JOB FILE-OR-CODE [RUNS]
tex() {
  _e=$1; _x=$2; _j=$3; _f=$4; _n=${5:-3}
  if [ $_e = luatex ]; then bin=luahbtex; fmt=lualatex; else bin=pdftex; fmt=pdflatex; fi
  D=$FMT/$_e
  i=0; while [ $i -lt $_n ]; do i=$((i+1))
    TEXINPUTS=".:$_x:$D:$TREE/texmf/tex//:" LUAINPUTS=".:$D:$TREE/texmf/tex//:" TEXFORMATS="$D:" \
      perl -e 'alarm 300; exec @ARGV' -- $bin -fmt=$fmt -interaction=nonstopmode -jobname=$_j "$_f" >/dev/null 2>&1
  done
  [ -f $_j.pdf ] && { pdftotext -layout $_j.pdf $_j.txt; pdfinfo -struct-text $_j.pdf > $_j.struct 2>&1; }
  printf '%-36s errors=%-3s tagpdf-warnings=%-3s %s\n' $_j "$(grep -c '^!' $_j.log)" \
    "$(grep 'Package tagpdf Warning' $_j.log | grep -vc unicode-math)" "$(grep -E '^(XFLOAT|XDBLFLOAT|SETTYPE|SETOPTIONS|TEST|BEGIN [^m]|END [^m])' $_j.log | tr '\n' '|' | cut -c1-200)"
  grep -h 'Package tagpdf Warning' $_j.log | grep -v unicode-math | sort | uniq -c | sed 's/^/    W/'
}
cmpf() { # a b ext...
  a=$1; b=$2; shift 2
  for x in "$@"; do
    if cmp -s $a.$x $b.$x; then echo "  $a.$x = $b.$x"; else echo "  $a.$x DIFFERS from $b.$x"; fi
  done
}
echo "### (a) caption with the float hooks"
tex pdftex "$CS" a2-stock a2-caption-user.tex 2
tex pdftex "$CH" a2-hook  a2-caption-user.tex 2
cmpf a2-stock a2-hook txt aux
tex pdftex "$CS" a3-stock a3-caption-user-tagging.tex
tex pdftex "$CH" a3-hook  a3-caption-user-tagging.tex
cmpf a3-stock a3-hook txt aux struct
tex pdftex "$NONE" a4-nested-H a4-nested-H.tex 1
for f in a5-plain a5-setspace a5-float a5-xdbl a5-bypass a5-rollback; do
  tex pdftex "$CS" $f-stock $f.tex 1
  tex pdftex "$CH" $f-hook  $f.tex 1
  cmpf $f-stock $f-hook txt
done
echo "### (b) caption interface"
for e in pdftex luatex; do
  for f in client-doc client-doc-notag client-doc-notag-hyperref; do
    tex $e "$NONE" $f-$e $f.tex
    sed 's/^/  LOF /' $f-$e.lof
  done
done
tex pdftex "$NONE" excerpt-new caption-excerpt-doc.tex
for c in article report memoir scrartcl amsart; do
  tex pdftex "$NONE" cls-$c "\def\cls{$c}\input cls-star" 2
  grep -i 'Normal\|Starred\|After' cls-$c.txt | sed 's/  */ /g; s/^/  /'
done
tex pdftex "$NONE" release-back release-back.tex 2
grep -v '^ *$' release-back.txt | sed 's/^/  /' | head -6
echo "### (c) caption/label socket"
for e in pdftex luatex; do
  for f in c-caption3-plug c-caption-remove c-inpar; do
    tex $e "$NONE" $f-$e $f.tex
    grep -E 'Caption|Lbl|^ +P' $f-$e.struct | head -8 | sed 's/^/  /'
  done
done
echo "### (d) float types"
for e in pdftex luatex; do
  tex $e "$NONE" d1-$e d1-manual-float.tex 2
  tex $e "$NONE" d2-nf12-$e d2-newfloat.tex 2
  tex $e "$NF" d2-nf12a-$e d2-newfloat.tex 2
  tex $e "$NF" d3-nf12a-$e d3-newfloat-caption.tex 2
  tex $e "$NONE" d10-$e d10-declare-in-group.tex 2
  tex $e "$NONE" d10b-$e d10b-declare-only-in-group.tex 2
done
for f in d6-tocbasic d7-memoir d8-captiontype d9-floatrowbytocbasic d11-frtb-newfloat d12-floatrow-newfloat; do
  tex pdftex "$NF" $f-nf12a-pdftex $f.tex 2
done
