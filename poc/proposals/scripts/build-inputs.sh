#!/bin/sh
# build-inputs.sh OUT
# Builds the package versions used by the client documents:
#   OUT/cap-stock  caption bundle from ../../source (branch fixes-combined, caption v3.6p)
#   OUT/cap-hook   the same, caption.sty patched with patches/caption-floathooks.diff (a)
#   OUT/nf12a      newfloat v1.2a: TeX Live's newfloat.dtx v1.2 + patches/newfloat-v1.2a.diff (d)
set -e
P=$(cd "$(dirname "$0")/.." && pwd)          # poc/proposals
SRC=$(cd "$P/../../source" && pwd)          # caption repository, source/
mkdir -p "$1"; O=$(cd "$1" && pwd)
lim() { t=$1; shift; perl -e 'alarm shift; exec @ARGV' -- "$t" "$@"; }
rm -rf "$O/cap-build" "$O/cap-stock" "$O/cap-hook" "$O/nf12a"
mkdir -p "$O/cap-build" "$O/cap-stock" "$O/cap-hook" "$O/nf12a"
cp -R "$SRC"/*.dtx "$SRC"/caption.ins "$SRC"/fallback "$O/cap-build/"
(cd "$O/cap-build" && lim 300 tex -interaction=batchmode caption.ins >/dev/null) || true
[ -f "$O/cap-build/caption.sty" ] || { echo "caption.ins failed" >&2; exit 1; }
for f in caption.sty caption3.sty subcaption.sty ltcaption.sty; do
  cp "$O/cap-build/$f" "$O/cap-stock/"; cp "$O/cap-build/$f" "$O/cap-hook/"
done
(cd "$O/cap-hook" && patch --batch -s caption.sty < "$P/patches/caption-floathooks.diff")
cp "$(kpsewhich newfloat.dtx)" "$(kpsewhich newfloat.ins)" "$O/nf12a/"
(cd "$O/nf12a" && patch --batch -s -p1 < "$P/patches/newfloat-v1.2a.diff" \
   && { lim 300 tex -interaction=batchmode newfloat.ins >/dev/null || true; })
grep -h 'ProvidesPackage{\(caption\|newfloat\)}' "$O"/cap-stock/caption.sty "$O"/nf12a/newfloat.sty
