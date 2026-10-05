#!/bin/sh
# run.sh STYDIR KERNEL(tl|stock|patched) OUTDIR [doc ...]
#
# Compiles every corpus document (docs/*.tex, or only the named ones) in every variant listed
# on its "% variants:" line (plain = as is, tag = \DocumentMetadata{tagging=on} prepended,
# meta = \DocumentMetadata{} prepended) with pdflatex and lualatex, 3 runs each, with STYDIR and
# $POC/newfloat first on TEXINPUTS. Per job, OUTDIR/<doc>[-<variant>]/<engine>/ gets:
#   <job>.log .aux .lof/.lot/... (all files LaTeX writes), <job>.pdf
#   status      exit codes of the 3 runs (124 = time limit)
#   errors.txt  number of "! " errors in the final log, then the error lines
#   warnings.txt  all Package/Class/LaTeX/Module warnings of the final log (one line each)
#   text.txt    pdftotext -layout
#   struct.txt  pdfinfo -struct-text (empty for untagged PDFs); structsum.txt  structsum.py line
# and OUTDIR/summary.tsv collects one row per job.
# Environment: JOBS (parallel jobs, default 4, keep <= 6), ENGINES (default "pdflatex lualatex"),
# TIMEOUT (seconds per run, default 180).
set -u
POC=${POC:?set POC to the directory with kernel-stock/, kernel/, newfloat/ and corpus/}
TOOLS=${TOOLS:?set TOOLS to the directory with structsum.py}
CORPUS=$POC/corpus
TEXBIN=/Library/TeX/texbin

if [ "${1:-}" = "--one" ]; then
  # internal: --one STYDIR KERNEL OUTDIR DOC VARIANT ENGINE
  STY=$2 KERNEL=$3 OUT=$4 DOC=$5 VAR=$6 ENG=$7
  case $VAR in plain) JOB=$DOC ;; *) JOB=$DOC-$VAR ;; esac
  D=$OUT/$JOB/$ENG
  rm -rf "$D"; mkdir -p "$D"
  case $VAR in
    plain) cp "$CORPUS/docs/$DOC.tex" "$D/$JOB.tex" ;;
    tag)   { printf '%s\n' '\DocumentMetadata{tagging=on}'; cat "$CORPUS/docs/$DOC.tex"; } > "$D/$JOB.tex" ;;
    meta)  { printf '%s\n' '\DocumentMetadata{}'; cat "$CORPUS/docs/$DOC.tex"; } > "$D/$JOB.tex" ;;
  esac
  case $KERNEL in
    tl)      CMD=$TEXBIN/$ENG; export TEXINPUTS="$STY:$POC/newfloat:" ;;
    stock)   CMD=$POC/kernel-stock/bin/$ENG; export TEXINPUTS="$STY:$POC/newfloat" ;;  # wrapper appends the rest
    patched) CMD=$POC/kernel/bin/$ENG; export TEXINPUTS="$STY:$POC/newfloat" ;;
  esac
  export max_print_line=10000 error_line=254 half_error_line=238
  cd "$D" || exit 1
  : > status
  for i in 1 2 3; do
    perl -e "alarm ${TIMEOUT:-180}; exec @ARGV" -- "$CMD" -interaction=nonstopmode "$JOB.tex" > /dev/null 2>&1 </dev/null
    rc=$?; [ $rc -eq 142 ] && rc=124   # SIGALRM
    echo "run$i $rc" >> status
  done
  LOG=$JOB.log
  { grep -c '^! ' "$LOG" 2>/dev/null || true; grep '^! ' "$LOG" 2>/dev/null; } > errors.txt
  # warnings: the first line plus continuation lines "(<pkg>)   ...", joined into one line
  awk '
    /^(Package|Class|Module) [^ ]+ Warning:|^LaTeX Warning:|^LaTeX [^ ]+ Warning:|^Package [^ ]+ Error:|^LaTeX [^ ]+ Error:/ { if (w!="") print w; w=$0; next }
    w!="" && /^\([^)]*\) / { sub(/^\([^)]*\) +/, " "); w=w $0; next }
    { if (w!="") print w; w="" }
    END { if (w!="") print w }' "$LOG" 2>/dev/null > warnings.txt
  if [ -f "$JOB.pdf" ]; then
    pdftotext -layout "$JOB.pdf" text.txt 2>/dev/null
    pdfinfo -struct-text "$JOB.pdf" > struct.txt 2>/dev/null || : > struct.txt
    python3 "$TOOLS/structsum.py" "$JOB.pdf" 2>/dev/null | sed 's/^[^ ]* //' > structsum.txt
  else
    echo "NO PDF" > text.txt; : > struct.txt; echo "NO PDF" > structsum.txt
  fi
  NE=$(head -1 errors.txt)
  cw=$(grep -c 'caption Warning\|caption Error' warnings.txt)
  tw=$(grep 'tagpdf' warnings.txt | grep -vc 'luamml')   # luamml notice is not counted
  hw=$(grep -c 'hyperref Warning' warnings.txt)
  ow=$(grep -vc 'caption Warning\|caption Error\|tagpdf\|hyperref Warning' warnings.txt)
  pages=$(pdfinfo "$JOB.pdf" 2>/dev/null | awk '/^Pages:/{print $2}')
  st=$(awk '{printf "%s%s", (NR>1?",":""), $2}' status)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$JOB" "$ENG" "$st" "$NE" "$cw" "$tw" "$hw" "$ow" "${pages:-0}" "$(cat structsum.txt)" > row.tsv
  exit 0
fi

[ $# -ge 3 ] || { echo "usage: $0 STYDIR tl|stock|patched OUTDIR [doc ...]" >&2; exit 2; }
STY=$(cd "$1" && pwd) || exit 2
KERNEL=$2
case $KERNEL in tl|stock|patched) ;; *) echo "kernel must be tl, stock or patched" >&2; exit 2 ;; esac
mkdir -p "$3" && OUT=$(cd "$3" && pwd) || exit 2
shift 3
if [ $# -gt 0 ]; then DOCS="$*"; else DOCS=$(cd "$CORPUS/docs" && ls *.tex | sed 's/\.tex$//'); fi
ENGINES=${ENGINES:-pdflatex lualatex}
SELF=$CORPUS/run.sh

for d in $DOCS; do
  vars=$(sed -n '1s/^% *variants: *//p' "$CORPUS/docs/$d.tex"); [ -n "$vars" ] || vars="plain tag"
  for v in $vars; do for e in $ENGINES; do printf '%s %s %s\n' "$d" "$v" "$e"; done; done
done | xargs -P "${JOBS:-4}" -L 1 sh -c 'exec "$0" --one "$1" "$2" "$3" "$4" "$5" "$6"' "$SELF" "$STY" "$KERNEL" "$OUT"

{ printf 'job\tengine\truns\terrors\tcaptionW\ttagpdfW\thyperrefW\totherW\tpages\tstructsum\n'
  cat "$OUT"/*/*/row.tsv | sort; } > "$OUT/summary.tsv"
echo "kernel=$KERNEL sty=$STY" > "$OUT/INFO"
column -t -s "$(printf '\t')" "$OUT/summary.tsv"
