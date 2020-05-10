#!/bin/bash

# test.sh
# Author: Axel Sommerfeldt (axel.sommerfeldt@f-m.fm)
# URL:    https://gitlab.com/axelsommerfeldt/caption

# shellcheck disable=SC2103,SC2164

help=false
if [[ $1 == "-?" || $1 == "--help" ]]
then
  printf "Syntax: ./test.sh [<sub-directory>]\n"
  printf "where <sub-directory> is either:\n"
  printf "  all   - compiles all test files (default)\n"
  printf "  clean - remove intermediate files only\n"
  printf "or one of:\n "
  help=true # print list of sub-directories without processing them
fi

basedir=$(pwd)
logfile="$basedir/test.log"

# Store argument as $dironly (default is "all" -> "*")
dironly=${1:-all}
if [[ $dironly == "all" ]]; then dironly="*"; fi
dirfound=false  # no matching directory was found so far

cleanup()
{
  # Remove interim files
  # Note: This removes all unstaged (new) files as well.
  git clean -fdx -e source/ltxdoc.cfg
}

compile_all()
{
  [[ -d $1 ]] || return # Process directories only

  if $help
  then
    # In help mode only print the sub-directory name
    printf " $1"
  # shellcheck disable=SC2053
  elif [[ $1 == $dironly ]]
  then
    dirfound=true # matching directory found

    # Compile all files in the given directory
    cd "$1"
    cp -a "$basedir"/tex/*.sty .

    shopt -s nullglob
    files=(*.dtx *.ltx *.tex)
    for file in "${files[@]}"
    do
      compile "$1" "$file"
    done

    cd ..
  fi
}

compile()
{
  # Skip example documents which purpose is to produce an error
  # (or cannot be compiled for a different reason)
  [[ $1 == "newfloat"    && $2 == "figurewithin-3.tex" ]] && return  # Inteded to fail w/ error
  [[ $1 == "ragged2e"    && $2 == "ragged2e_4.tex"     ]] && return  # Intended to fail w/ error
  [[ $1 == "ragged2e"    && $2 == "ragged2e_5.tex"     ]] && return  # Intended to fail w/ error
  [[ $1 == "email"       && $2 == "2009-09-29.tex"     ]] && return  # Related to floatrow, should produce error
  [[ $1 == "other"       && $2 == "2007-09-13.tex"     ]] && return  # labelsep=newline + \setcaphanging, should produce error
  [[ $1 == "other"       && $2 == "2012-09-21.tex"     ]] && return  # Bug in fltpage
  [[ $1 == "other"       && $2 == "2013-01-09.tex"     ]] && return  # Bug in fltpage
  [[ $1 == "sourceforge" && $2 == "ticket_2.tex"       ]] && return  # Bug in fltpage
  [[ $1 == "sourceforge" && $2 == "ticket_4.tex"       ]] && return  # TODO: Adaption to hvfloat
  [[ $1 == "sourceforge" && $2 == "ticket_12.tex"      ]] && return  # Can't compile tufte-book
  [[ $1 == "sourceforge" && $2 == "ticket_26.tex"      ]] && return  # Bug in refcheck
  [[ $1 == "sourceforge" && $2 == "ticket_37.tex"      ]] && return  # TODO: \iflistof
  [[ $1 == "sourceforge" && $2 == "ticket_40.tex"      ]] && return  # Bug in catoptions
  [[ $1 == "sourceforge" && $2 == "ticket_43.tex"      ]] && return  # subcaption + subfig, should produce error
  [[ $1 == "sourceforge" && $2 == "ticket_44.tex"      ]] && return  # \captionof{subfigure}, should produce error
  [[ $1 == "sourceforge" && $2 == "ticket_47.tex"      ]] && return  # TODO: \DeclareCaptionListHook
  [[ $1 == "gitlab"      && $2 == "issue_29.tex"       ]] && return  # Needs Culmus fonts to compile
  [[ $1 == "gitlab"      && $2 == "issue_35.tex"       ]] && return  # Needs <whatever> to compile (greek & farsi)

  # Compile document three times (so interim files will be used)
  pdflatex "$2" || failed "$1" "$2"
  pdflatex "$2" || failed "$1" "$2"
  pdflatex "$2" || failed "$1" "$2"
  printf "Compiling %s/%s passed.\n" "$1" "$2" | tee -a "$logfile"
}

failed()
{
  # Print error message and exit
  printf "\n*** Compiling %s/%s failed.\n" "$1" "$2" | tee -a "$logfile"
  exit 1
}

# Do not remove intermediate files in help mode
if ! $help
then
  # Remove intermediate files
  cleanup
  [[ $dironly != "clean" ]] || exit
fi

# Compile all package documentations
compile_all "source"

# Compile all test documents
cd test
dirs=(*)
for dir in "${dirs[@]}"
do
  compile_all "$dir"
done
cd ..

# Compile all issue documents
cd issues
dirs=(*)
for dir in "${dirs[@]}"
do
  compile_all "$dir"
done
cd ..

# Print test result
if $help
then
  printf "\n"
elif $dirfound
then
  printf "\nThat's all, folks!\n"
else
  printf "*** No sub-directory '%s' found.\n" "$dironly" >&2
fi

