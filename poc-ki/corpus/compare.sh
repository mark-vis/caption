#!/bin/bash
# compare.sh OUT1 OUT2 [-v]
# Per job (<doc>[-<variant>]/<engine>) lists which outputs of run.sh differ:
#   status errors warnings text aux lists(.lof/.lot/.lop/.loc/.lol) out struct structsum
# "aux(mcid-only)" = the .aux files differ only in tagpdf mcid label records.
# -v also prints the diffs (except struct, which is long; diff those by hand).
# Exit status 0 if nothing differs, 1 otherwise.
A=$(cd "${1:?usage: compare.sh OUT1 OUT2 [-v]}" && pwd) || exit 2; B=$(cd "${2:?usage: compare.sh OUT1 OUT2 [-v]}" && pwd) || exit 2; V=${3:-}
ndiff=0
for j in $( { cd "$A" && ls -d */*/ 2>/dev/null; cd "$B" && ls -d */*/ 2>/dev/null; } | sed 's,/$,,' | sort -u); do
  if [ ! -d "$A/$j" ] || [ ! -d "$B/$j" ]; then echo "$j: only in one tree"; ndiff=$((ndiff+1)); continue; fi
  job=${j%/*}; diffs=""
  for item in status errors.txt warnings.txt text.txt aux lof lot lop loc lol out struct.txt structsum.txt; do
    case $item in *.txt|status) fa=$A/$j/$item fb=$B/$j/$item ;; *) fa=$A/$j/$job.$item fb=$B/$j/$job.$item ;; esac
    [ -f "$fa" ] || [ -f "$fb" ] || continue
    if [ "$item" = aux ] && ! cmp -s "$fa" "$fb" 2>/dev/null && [ -f "$fa" ] && [ -f "$fb" ] &&
       cmp -s <(grep -v 'new@label@record{mcid-' "$fa") <(grep -v 'new@label@record{mcid-' "$fb"); then
      diffs="$diffs aux(mcid-only)"; continue
    fi
    if ! cmp -s "$fa" "$fb" 2>/dev/null; then
      diffs="$diffs ${item%.txt}"
      if [ "$V" = "-v" ] && [ "$item" != struct.txt ]; then
        echo "=== $j $item"; diff "$fa" "$fb" | head -40
      fi
    fi
  done
  if [ -n "$diffs" ]; then echo "$j: DIFF$diffs"; ndiff=$((ndiff+1)); else echo "$j: same"; fi
done
echo "jobs differing: $ndiff"
[ $ndiff -eq 0 ]
