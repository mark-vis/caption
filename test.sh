#!/bin/bash
#
# 2019-08-30: 1st version

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
  [[ $1 == "email" && $2 == "2009-09-29.tex" ]] && return
  [[ $1 == "other" && $2 == "2007-09-13.tex" ]] && return

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

