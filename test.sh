#!/bin/bash

compile()
{
  printf "%s/%s...\n" "$dir" "$file"
  pdflatex "$2" || failed "$1" "$2"
  pdflatex "$2" || failed "$1" "$2"
  pdflatex "$2" || failed "$1" "$2"
}

failed()
{
  printf "\nCompiling %s/%s failed.\n" "$1" "$2"
  exit 1
}

# Compile all documents
cd source
files=(*.dtx *.tex)
for file in "${files[@]}"
do
  compile "$dir" "$file"
done
cd ..

# Compile all issues
cd issues
dirs=(*)
for dir in "${dirs[@]}"
do
  if [ -d $dir ]
  then
    printf "%s...\n" "$dir"
    cd "$dir"
    cp -a ../../tex/*.sty .

    files=(*.tex)
    for file in "${files[@]}"
    do
      compile "$dir" "$file"
    done

    cd ..
  fi
done
cd ..

printf "\nThat's all, folks!\n"

