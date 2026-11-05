#!/bin/sh
#
# 2ctan.sh
# Builds the CTAN archive caption_YYYY-MM-DD.tar.gz in the current
# directory (which must be the top level of the repository).
#
# Usage: ./2ctan.sh [--clean]
#   --clean  first remove all untracked and ignored files from the working
#            tree (like "./test.sh clean", i.e. "git clean -fdx"), including
#            earlier archives, but keep the built documentation doc/*.pdf.
#
# The documentation in doc/*.pdf must be up to date before running this script;
# doc/caption.pdf is not tracked by git, so build it first. The script stops
# with an error if doc/caption.pdf is missing.
# Uploading is done by hand via https://ctan.org/upload (ctanupload, below,
# no longer works).
#
# 2011-10-09: 1st version
# 2011-10-10: Log file will be copied as ".LOG" now (needs package "mmv")
# 2011-11-06: File CHANGELOG added to distribution
# 2012-03-15: Option "-p" added to "cp" command
# 2013-01-08: "-U dante" changed to "-u http://www.ctan.org/upload"
# 2013-02-03: Adapted to new SVN directory structure
# 2015-09-17: Revised, ctanupload commented out since currently-not-working
# 2020-08-01: *.sto files added to distribution
# 2022-01-05: Outdated documentation removed from distribution
# 2022-02-20: Fallback sources added to distribution
# 2023-07-30: captiondoc.cls added to source files
# 2026-11-05: Portable (macOS): "date +%F" instead of "date --rfc-3339=date",
#             temporary directory via mktemp, "./test.sh clean" only with
#             option --clean (keeping doc/*.pdf), no macOS metadata (._* files)
#             in the archive, error if doc/caption.pdf is missing
#
# Needs: ctanify (TeX Live) with the Perl module File::Copy::Recursive, zip, tar

set -e

clean=false
for arg in "$@"
do
  case "$arg" in
    --clean) clean=true ;;
    *) printf '*** Invalid argument "%s". Usage: %s [--clean]\n' "$arg" "$0" >&2; exit 1 ;;
  esac
done

if [ ! -f source/caption.ins ]
then
  printf '*** Run this script from the top level of the repository\n' >&2
  exit 1
fi

if $clean
then
  # Same as "./test.sh clean", but keep the (untracked) built documentation
  git clean -fdx -e source/ltxdoc.cfg -e '/doc/*.pdf'
fi

if [ ! -f doc/caption.pdf ]
then
  printf '*** doc/caption.pdf not found; build it first\n' >&2
  exit 1
fi

dist_dir=$(pwd)
archive="$dist_dir/caption_$(date +%F).tar.gz"
temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/caption.XXXXXX")
# Remove the temporary directory on every exit, unless ctanify fails (below)
trap 'rm -fr "$temp_dir"' EXIT

# Keep macOS tar from adding ._* (AppleDouble) files to the archive
COPYFILE_DISABLE=1
export COPYFILE_DISABLE

cp -a source/*.ins source/*.dtx source/*.cls source/*.eps source/fallback "$temp_dir"
cp -a tex/*.sty tex/*.sto "$temp_dir"
cp -a doc/*.pdf "$temp_dir"
cp -a README CHANGELOG SUMMARY "$temp_dir"
cd "$temp_dir"

# shellcheck disable=SC2035
if ctanify caption.ins \
	"*.cls=source/latex/caption" \
	"*.eps=source/latex/caption" \
	"fallback/v1/*.dtx=source/latex/caption/fallback/v1" \
	"fallback/v2.0/*.dtx=source/latex/caption/fallback/v2.0" \
	"fallback/v2.1/*.dtx=source/latex/caption/fallback/v2.1" \
	"fallback/v3.0/*.dtx=source/latex/caption/fallback/v3.0" \
	"fallback/v3.1/*.dtx=source/latex/caption/fallback/v3.1" \
	"fallback/v3.2/*.dtx=source/latex/caption/fallback/v3.2" \
	"fallback/v3.3/*.dtx=source/latex/caption/fallback/v3.3" \
	"fallback/v3.4/*.dtx=source/latex/caption/fallback/v3.4" \
	"fallback/v3.5/*.dtx=source/latex/caption/fallback/v3.5" \
	"*.sty=tex/latex/caption" \
	"*.sto=tex/latex/caption" \
	README "CHANGELOG=doc/latex/caption" "SUMMARY=doc/latex/caption" *.pdf
then
  cp -a "$temp_dir/caption.tar.gz" "$archive"
  cd "$dist_dir"
  rm -fr "$temp_dir"
  printf 'Created %s\n' "$archive"

#  ctanupload -l -p -u http://www.ctan.org/upload \
#    --contribution=caption \
#    --name "Axel Sommerfeldt" --email axel.sommerfeldt@f-m.fm \
#    --summary-file $dist_dir/SUMMARY \
#    --directory=/macros/latex/contrib/caption \
#    --DoNotAnnounce=0 \
#    --license=free --freeversion=lppl \
#    --file=$archive
else
  trap - EXIT
  printf '*** ctanify failed; temporary files are kept in %s\n' "$temp_dir" >&2
  exit 1
fi
