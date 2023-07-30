#!/bin/sh
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
#
# Needs on CentOS/Fedora: mmv perl-File-Copy-Recursive perl-HTML-FormatText* perl-WWW-Mechanize* perl-XML-TreeBuilder
#
set -e
dist_dir=$(pwd)
#
./test.sh clean
#
rm -fr /tmp/caption
mkdir /tmp/caption
cp -a source/*.ins source/*.dtx source/*.cls source/*.eps source/fallback /tmp/caption
cp -a tex/*.sty tex/*.sto /tmp/caption
cp -a doc/*.pdf /tmp/caption
cp -a README CHANGELOG SUMMARY /tmp/caption
cd /tmp/caption
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
  cp -a /tmp/caption/caption.tar.gz "$dist_dir/caption_$(date --rfc-3339=date).tar.gz"
  cd "$dist_dir"

#  ctanupload -l -p -u http://www.ctan.org/upload \
#    --contribution=caption \
#    --name "Axel Sommerfeldt" --email axel.sommerfeldt@f-m.fm \
#    --summary-file $dist_dir/doc/SUMMARY \
#    --directory=/macros/latex/contrib/caption \
#    --DoNotAnnounce=0 \
#    --license=free --freeversion=lppl \
#    --file=/tmp/caption/caption.tar.gz
fi

