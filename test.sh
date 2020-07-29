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
  printf "or one of:\n"
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
  [[ -d $2 ]] || return # Process directories only

  # shellcheck disable=SC2053
  if $help
  then
    # In help mode only print the sub-directory name
    if [[ $1 == "." ]]
    then
      printf "  %s\n" "$2"
    else
      printf "  %s/%s\n" "$1" "$2"
    fi
  elif [[ "$1/$2" == $dironly || "$2" == $dironly ]]
  then
    dirfound=true # matching directory found

    # Compile all files in the given directory
    cd "$2"
    cp -a "$basedir"/tex/*.sty .

    shopt -s nullglob
    files=(*.dtx *.ltx *.tex)
    for file in "${files[@]}"
    do
      compile "$1" "$2" "$file"
    done

    cd ..
  fi
}

compile()
{
  # Skip example documents which purpose is to produce an error
  # (or cannot be compiled for a different reason)
  [[ $2 == "floatrow"    && $3 == "floatrow.dtx"       ]] && return  # ! Arithmetic overflow.
  [[ $2 == "floatrow"    && $3 == "floatrow-rus.tex"   ]] && return  # ! Arithmetic overflow.
  [[ $2 == "floatrow"    && $3 == "frsample04.tex"     ]] && return  # Does not compile with pdflatex
  [[ $2 == "floatrow"    && $3 == "frsample10.tex"     ]] && return  # Does not compile with pdflatex
  [[ $2 == "floatrow"    && $3 == "frsample11.tex"     ]] && return  # Does not compile with pdflatex
  [[ $2 == "floatrow"    && $3 == "fr-sample.tex"      ]] && return  # No need to test this (sample body)
  [[ $2 == "floatrow"    && $3 == "pictures.tex"       ]] && return  # No need to test this
  [[ $2 == "floatrow"    && $3 == "r-longtable.tex"    ]] && return  # No need to test this
  [[ $2 == "floatrow"    && $3 == "s-longtable.tex"    ]] && return  # No need to test this
  [[ $2 == "newfloat"    && $3 == "figurewithin-3.tex" ]] && return  # Intended to fail w/ error
  [[ $2 == "ragged2e"    && $3 == "ragged2e_4.tex"     ]] && return  # Intended to fail w/ error
  [[ $2 == "ragged2e"    && $3 == "ragged2e_5.tex"     ]] && return  # Intended to fail w/ error
  [[ $2 == "email"       && $3 == "2009-09-29.tex"     ]] && return  # Intended to fail w/ error (related to floatrow)
  [[ $2 == "other"       && $3 == "2007-09-13.tex"     ]] && return  # Intended to fail w/ error: labelsep=newline + \setcaphanging
  [[ $2 == "other"       && $3 == "2012-09-21.tex"     ]] && return  # Bug in fltpage
  [[ $2 == "other"       && $3 == "2013-01-09.tex"     ]] && return  # Bug in fltpage
  [[ $2 == "sourceforge" && $3 == "ticket_2.tex"       ]] && return  # Bug in fltpage
  [[ $2 == "sourceforge" && $3 == "ticket_4.tex"       ]] && return  # TODO: Adaption to hvfloat
  [[ $2 == "sourceforge" && $3 == "ticket_12.tex"      ]] && return  # Can't compile tufte-book
  [[ $2 == "sourceforge" && $3 == "ticket_26.tex"      ]] && return  # Bug in refcheck
  [[ $2 == "sourceforge" && $3 == "ticket_37.tex"      ]] && return  # TODO: \iflistof
  [[ $2 == "sourceforge" && $3 == "ticket_40.tex"      ]] && return  # Bug in catoptions
  [[ $2 == "sourceforge" && $3 == "ticket_43.tex"      ]] && return  # Intended to fail w/ error: subcaption + subfig
  [[ $2 == "sourceforge" && $3 == "ticket_44.tex"      ]] && return  # Intended to fail w/ error: \captionof{subfigure}
  [[ $2 == "sourceforge" && $3 == "ticket_47.tex"      ]] && return  # TODO: \DeclareCaptionListHook
  [[ $2 == "gitlab"      && $3 == "issue_25.tex"       ]] && return  # Doomed to fail: \newsubfloat + subcaption package
  [[ $2 == "gitlab"      && $3 == "issue_29.tex"       ]] && return  # Needs Culmus fonts to compile
  [[ $2 == "gitlab"      && $3 == "issue_35.tex"       ]] && return  # Needs <whatever> to compile (greek & farsi)
  [[ $2 == "gitlab"      && $3 == "issue_65.tex"       ]] && return  # Doomed to fail: frontiers document class + subcaption package

  # Compile document three times (so interim files will be used)
  pdflatex "$3" || failed "$1" "$2" "$3"
  pdflatex "$3" || failed "$1" "$2" "$3"
  pdflatex "$3" || failed "$1" "$2" "$3"
  printf "Compiling %s/%s/%s passed.\n" "$1" "$2" "$3" | tee -a "$logfile"
}

failed()
{
  # Print error message and exit
  printf "\n*** Compiling %s/%s/%s failed.\n" "$1" "$2" "$3" | tee -a "$logfile"
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
compile_all "." "source"

# Compile all test documents
cd test
dirs=(*)
for dir in "${dirs[@]}"
do
  compile_all "test" "$dir"
done
cd ..

# Compile all issue documents
cd issues
dirs=(*)
for dir in "${dirs[@]}"
do
  compile_all "issues" "$dir"
done
cd ..

# Print test result
if $help
then
  :
elif $dirfound
then
  printf "\nThat's all, folks!\n"
else
  printf "*** No sub-directory '%s' found.\n" "$dironly" >&2
fi

