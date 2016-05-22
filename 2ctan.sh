#!/bin/sh
#
# 2011-10-09: 1st version
# 2011-10-10: Log file will be copied as ".LOG" now (needs package "mmv")
# 2011-11-06: File CHANGELOG added to distribution
# 2012-03-15: Option "-p" added to "cp" command
# 2013-01-08: "-U dante" changed to "-u http://www.ctan.org/upload"
# 2013-02-03: Adapted to new SVN directory structure
# 2015-09-17: Revised, ctanupload commented out since currently-not-working
#
# Needs on CentOS/Fedora: mmv perl-File-Copy-Recursive perl-HTML-FormatText* perl-WWW-Mechanize* perl-XML-TreeBuilder
#
dist_dir=$(pwd)
#
rm -fr /tmp/caption
mkdir /tmp/caption
cp -a source/*.ins source/*.dtx source/*.tex source/*.eps /tmp/caption
cp -a tex/*.sty /tmp/caption
cp -a doc/README doc/CHANGELOG doc/SUMMARY doc/*.pdf /tmp/caption
cd /tmp/caption
ctanify caption.ins "*.tex=source/latex/caption" "*.eps=source/latex/caption" README "CHANGELOG=doc/latex/caption" "SUMMARY=doc/latex/caption" *.pdf
#
if [ $? -eq 0 ]; then
  cp -a /tmp/caption/caption.tar.gz $dist_dir/caption_$(date --rfc-3339=date).tar.gz
  cd $dist_dir

#  ctanupload -l -p -u http://www.ctan.org/upload \
#    --contribution=caption \
#    --name "Axel Sommerfeldt" --email axel.sommerfeldt@f-m.fm \
#    --summary-file $dist_dir/doc/SUMMARY \
#    --directory=/macros/latex/contrib/caption \
#    --DoNotAnnounce=0 \
#    --license=free --freeversion=lppl \
#    --file=/tmp/caption/caption.tar.gz
fi

