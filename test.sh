#!/bin/bash

basedir=$(pwd)
logfile="$basedir/test.log"

cleanup()
{
  # Remove interim files
  git clean -fdx
}

compile_all()
{
  # Compile all files in the given directory
  cd "$1"
  cp -a $basedir/tex/*.sty .

  shopt -s nullglob
  files=(*.dtx *.ltx *.tex)
  for file in "${files[@]}"
  do
    compile "$1" "$file"
  done

  cd ..
}

compile()
{
  # Skip example documents which purpose is to produce an error
  # (or cannot be compiled for a different reason)
  [[ $1 == "email" && $2 == "2009-09-29.tex" ]] && return       # Related to floatrow, should produce error
  [[ $1 == "other" && $2 == "2007-09-13.tex" ]] && return       # labelsep=newline + \setcaphanging, should produce error
  [[ $1 == "other" && $2 == "2012-09-21.tex" ]] && return       # Bug in fltpage
  [[ $1 == "other" && $2 == "2013-01-09.tex" ]] && return       # Bug in fltpage
  [[ $1 == "sourceforge" && $2 == "ticket_2.tex"  ]] && return  # Bug in fltpage
  [[ $1 == "sourceforge" && $2 == "ticket_4.tex"  ]] && return  # TODO: Adaption to hvfloat
  [[ $1 == "sourceforge" && $2 == "ticket_8.tex"  ]] && return  # TODO: Should be fixed!
  [[ $1 == "sourceforge" && $2 == "ticket_12.tex" ]] && return  # Can't compile tufte-book
  [[ $1 == "sourceforge" && $2 == "ticket_18.tex" ]] && return  # TODO: \continuedfloat
  [[ $1 == "sourceforge" && $2 == "ticket_26.tex" ]] && return  # Bug in refcheck
  [[ $1 == "sourceforge" && $2 == "ticket_37.tex" ]] && return  # TODO: \iflistof
  [[ $1 == "sourceforge" && $2 == "ticket_40.tex" ]] && return  # Bug in catoptions
  [[ $1 == "sourceforge" && $2 == "ticket_43.tex" ]] && return  # subcaption + subfig, should produce error
  [[ $1 == "sourceforge" && $2 == "ticket_47.tex" ]] && return  # TODO: \DeclareCaptionListHook

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

cleanup

# Compile all documents
compile_all "source"

# Compile all test documents
cd test
dirs=(*)
for dir in "${dirs[@]}"
do
  if [ -d $dir ]
  then
    compile_all "$dir"
  fi
done
cd ..

# Compile all issue documents
cd issues
dirs=(*)
for dir in "${dirs[@]}"
do
  if [ -d $dir ]
  then
    compile_all "$dir"
  fi
done
cd ..

#cleanup
printf "\nThat's all, folks!\n" | tee -a "$logfile"

