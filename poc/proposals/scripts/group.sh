#!/bin/sh
# group.sh WORK VARIANT:GROUP -- run the l3build jobs of one group (used by run-checks.sh)
W=$1; g=$2; v=${g%%:*}; k=${g#*:}; T=$W/t-$v-$k
J=$(cd "$(dirname "$0")" && pwd)/check-job.sh
case $k in
  base)  sh "$J" "$T" base; case $v in stock|all|a) sh "$J" "$T" lthooks ;; esac ;;
  float) sh "$J" "$T" float ;;
  table) sh "$J" "$T" table-pdftex; sh "$J" "$T" table-luatex; sh "$J" "$T" block ;;
esac > "$W/logs/$v-$k.log" 2>&1
echo "done $g"
