#!/bin/sh
# run-checks.sh WORK [CLONE]
# Reproduces the l3build checks and the client documents of PROPOSALS.md,
# section "Verification of the combined patch".
#   WORK   scratch directory (needs about 3 GB: one latex2e copy per job group)
#   CLONE  an existing clone of https://github.com/latex3/latex2e
#          (default: cloned into WORK/latex2e); it is only read
# JOBS=n   number of parallel groups (default 7)
# Variants: stock = develop 829e56a15 unpatched, all = patches/series/*.patch,
#           a, b, d = patches/standalone/*.patch alone.
set -e
P=$(cd "$(dirname "$0")/.." && pwd)          # poc/proposals
REV=829e56a15
mkdir -p "$1"; W=$(cd "$1" && pwd); C=${2:-$W/latex2e}
JOBS=${JOBS:-7}
[ -d "$C/.git" ] || git clone -q https://github.com/latex3/latex2e.git "$C"
rm -rf "$W/pristine"; git clone -q "$C" "$W/pristine"; git -C "$W/pristine" checkout -q $REV
tree() { # VARIANT GROUP: make WORK/t-VARIANT-GROUP
  T=$W/t-$1-$2; rm -rf "$T"; cp -R "$W/pristine" "$T"
  case $1 in
    stock) ;;
    all)   for p in "$P"/patches/series/*.patch; do git -C "$T" apply --whitespace=nowarn "$p"; done ;;
    a)     git -C "$T" apply --whitespace=nowarn "$P/patches/standalone/a-float-hooks.patch" ;;
    b)     git -C "$T" apply --whitespace=nowarn "$P/patches/standalone/b-caption-interface.patch" ;;
    d)     git -C "$T" apply --whitespace=nowarn "$P/patches/standalone/d-tagging-float-types.patch" ;;
  esac
}
GRPS="stock:base stock:float stock:table all:base all:float all:table a:base a:float b:base b:float d:float"
for g in $GRPS; do tree ${g%%:*} ${g#*:}; done
mkdir -p "$W/logs"
for g in $GRPS; do echo $g; done | xargs -P $JOBS -L 1 sh "$P/scripts/group.sh" "$W"
# summary: every failing test with its distinct differing lines
for g in $GRPS; do
  v=${g%%:*}; k=${g#*:}
  for f in "$W"/t-$v-$k/build/test*/*.diff; do
    [ -f "$f" ] || continue
    echo "$v $(basename "$f"): $(grep -E '^[-+!] ' "$f" | sort -u | tr '\n' '|' | cut -c1-200)"
  done
  grep -H 'Failed to find input' "$W/logs/$v-$k.log" || true
done > "$W/summary.txt"
cat "$W/summary.txt"
# client documents against the formats of the table groups (they contain
# pdflatex.fmt/lualatex.fmt and the unpacked latex-lab files)
sh "$P/scripts/build-inputs.sh" "$W/inputs"
for v in stock all; do
  F=$W/fmt-$v; rm -rf "$F"; mkdir -p "$F"
  cp -R "$W/t-$v-table/build/test-config-table-pdftex" "$F/pdftex"
  cp -R "$W/t-$v-table/build/test-config-table-luatex" "$F/luatex"
  sh "$P/scripts/docs.sh" "$F" "$W/t-$v-table" "$W/inputs/cap-stock" "$W/inputs/cap-hook" \
     "$W/inputs/nf12a" "$P/mwe" "$W/docs-$v" > "$W/docs-$v.txt" 2>&1
done
for x in txt aux; do cmp -s "$W/docs-stock/a2-stock.$x" "$W/docs-all/a2-hook.$x" \
  && echo "a2: develop + caption = combined patch + caption with hooks ($x)"; done
for x in txt aux struct; do cmp -s "$W/docs-stock/a3-stock.$x" "$W/docs-all/a3-hook.$x" \
  && echo "a3: develop + caption = combined patch + caption with hooks ($x)"; done
echo "client documents: $W/docs-all.txt (combined patch), $W/docs-stock.txt (develop)"
