#!/bin/bash

# test.sh
# Author: Axel Sommerfeldt (axel.sommerfeldt@f-m.fm)
# URL:    https://gitlab.com/axelsommerfeldt/caption
# Date:   2020-09-13

# shellcheck disable=SC2155

basedir=$(pwd)

all=true            # default: Target "all"
disabled_cases=()   # default: Compile all testcases
exit_on_error=true  # default: Exit after error
interactive=true    # default: Interactive mode
output_file=""      # default: Don't generate report file

shopt -s nullglob

function main
{
  local gl_tests=0
  local gl_failures=0
  local gl_disabled=0
  local gl_content=""
  local gl_start=$(timestamp)

  local disable_arg=false
  local interactive_arg=false
  local output_arg=false

  local arg
  for arg in "$@"
  do
    if [[ $arg == "-?" || $arg == "--help" ]]
    then
      printf "Usage: ./test.sh [OPTION]... [all|clean|DIRECTORY|FILE]...\n"
      printf "\n"
      printf "  -d, --disable=FILE      don't compile FILE (or DIRECTORY)\n"
      printf "  -i, --interactive=BOOL  set interactive mode (default:true)\n"
      printf "  -o, --output=FILE       generate report file\n"
      printf "\n"
      exit 1
    elif [[ $arg == "-d" || $arg == "--disable" ]]
    then
      disable_arg=true
    elif $disable_arg
    then
      disable "$arg"
      disable_arg=false
    elif [[ ${arg:0:2} == "-d" ]]
    then
      disable "${arg:2}"
    elif [[ ${arg:0:10} == "--disable=" ]]
    then
      disable "${arg:10}"
    elif [[ $arg == "-i" || $arg == "--interactive" ]]
    then
      interactive_arg=true
    elif $interactive_arg
    then
      interactive=$(boolean "$arg")
      interactive_arg=false
    elif [[ ${arg:0:2} == "-i" ]]
    then
      interactive=$(boolean "${arg:2}")
    elif [[ ${arg:0:14} == "--interactive=" ]]
    then
      interactive=$(boolean "${arg:14}")
    elif [[ $arg == "-o" || $arg == "--output" ]]
    then
      output_arg=true
    elif $output_arg
    then
      output_file="$arg"
      exit_on_error=false
      interactive=false
      output_arg=false
    elif [[ ${arg:0:2} == "-o" ]]
    then
      output_file="${arg:2}"
      exit_on_error=false
      interactive=false
    elif [[ ${arg:0:9} == "--output=" ]]
    then
      output_file="${arg:9}"
      exit_on_error=false
      interactive=false
    elif [[ $arg == "all" ]]
    then
      all=true
    elif [[ $arg == "clean" ]]
    then
      clean
      all=false
    else
      all=false

      # Remove trailing /
      if [[ ${arg:${#arg}-1} == "/" ]]
      then
         arg=${arg:0:${#arg}-1}
      fi

      # Compile either directory content or file
      if [[ -d "$basedir/$arg" ]]
      then
        compile_dir "$arg"
      elif [[ -f "$basedir/$arg" ]]
      then
        compile_file "$arg"
      else
        printf "*** Invalid argument '%s'.\n" "$arg"
        exit 1
      fi
    fi
  done

  if $all
  then
    # Compile all files in all directories
    local dirs=(*)
    local dir
    for dir in "${dirs[@]}"
    do
      if [[ -d "$basedir/$dir" ]]
      then
        is_disabled "$dir" || compile_dir "$dir"
      fi
    done
  fi

  local gl_end=$(timestamp)

  # Generate report file, if requested
  if [[ -n $output_file ]]
  then
    cd "$basedir" || exit
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<testsuites name=\"%s\" tests=\"%d\" failures=\"%d\" disabled=\"%d\" time=\"%s\">\n%s</testsuites>\n' "AllTests" "$gl_tests" "$gl_failures" "$gl_disabled" "$(timestamp_diff "$gl_start" "$gl_end")" "$gl_content" > "$output_file"
  fi

  # Return 0 if no failures occured, 1 otherwise
  (( gl_failures == 0 ))
}

function clean
{
  # Remove interim files
  # Note: This removes all unstaged (new) files as well.
  git clean -fdx -e source/ltxdoc.cfg
}

function compile_dir
{
  # Compile all files in all sub-directories

  local dir="$1"

  cd "$basedir/$dir" || exit

  local subdirs=(*)
  local files=(*.dtx *.ltx *.tex)

  local subdir
  for subdir in "${subdirs[@]}"
  do
    if [[ -d "$basedir/$dir/$subdir" ]]
    then
      is_disabled "$dir/$subdir" || compile_dir "$dir/$subdir"
    fi
  done

  if (( ${#files[@]} > 0 ))
  then
    pre_compile_files

    local tests=0
    local failures=0
    local disabled=0
    local content=""
    local start=$(timestamp)

    local file
    for file in "${files[@]}"
    do
      is_disabled "$dir/$file" || compile_dir_file "$dir" "$file"
    done

    local end=$(timestamp)

    post_compile_files
  fi
}

function compile_file
{
  # Compile a single file

  local dir=$(dirname "$1")
  local file=$(basename "$1")

  pre_compile_files

  local tests=0
  local failures=0
  local disabled=0
  local content=""
  local start=$(timestamp)

  compile_dir_file "$dir" "$file"

  local end=$(timestamp)

  post_compile_files
}

function pre_compile_files
{
  # Change directory
  cd "$basedir/$dir" || exit

  # Update local LaTeX packages
  cp -a "$basedir"/tex/*.sty "$basedir"/tex/*.sto .
}

function post_compile_files
{
  # Generate report
  local temp
  printf -v temp '<testsuite name=\"%s\" tests=\"%d\" failures=\"%d\" disabled=\"%d\" time=\"%s\">\n%s</testsuite>\n' "$dir" "$tests" "$failures" "$disabled" "$(timestamp_diff "$start" "$end")" "$content"
  gl_content+="$temp"
}

function compile_dir_file
{
  # Compile a single file as "testcase" as part of a "testsuite"

  ((++tests))
  ((++gl_tests))

  local start=$(timestamp)
  compile "$2"
  local result=$?
  local end=$(timestamp)

  local temp
  if (( result == 0 ))
  then
    printf "Compiling %s/%s passed.\n" "$1" "$2"
    printf -v temp '<testcase name="%s" time="%s" />\n' "$2" "$(timestamp_diff "$start" "$end")"
  else
    printf "\n*** Compiling %s/%s failed.\n" "$1" "$2"
    printf -v temp '<testcase name="%s" time="%s"><failure message="%s" type="ERROR" /></testcase>\n' "$2" "$(timestamp_diff "$start" "$end")" "$(xml_escape "$message")"

    ((++failures))
    ((++gl_failures))

    if $exit_on_error
    then
      exit $result
    fi
  fi

  content+="$temp"
  return $result
}

function compile
{
  # Compile document up to three times (so interim files will be used)

  local logfile="${1%.*}.log"

  # shellcheck disable=SC2034
  for i in {1..3}
  do
    local result log

    if $interactive
    then
      log=""
      pdflatex "$1"
      result=$?
    else
#     sleep 0.1
      log=$(pdflatex -halt-on-error "$1")
      result=$?
    fi

    if (( result != 0 ))
    then
      printf '%s' "$log"
      message=$(tail -n1 "$logfile")  # failure message for report file
      return $result
    fi
    if ! grep -Fq "Rerun to get" "$logfile"
    then
      break
    fi
  done
}

function boolean
{
  # Convert boolean value to either "false" or "true"

  if [[ $1 == "0" || $1 == "false" || $1 == "no" ]]
  then
    printf 'false\n'
  elif [[ $1 == "1" || $1 == "true" || $1 == "yes" ]]
  then
    printf 'true\n'
  else
    printf "*** Invalid boolean value '%s'.\n" "$1"
    exit 1
  fi
}

function disable
{
  # Disable a testsuite or testcase

  disabled_cases+=( "$1" )
}

function is_disabled
{
  # Test if the given testsuite or testcase is disabled

  local d
  for d in "${disabled_cases[@]}"
  do
    if [[ $d == "$1" ]]
    then
      ((++disabled))
      ((++gl_disabled))
      return 0
    fi
  done
  return 1
}

function timestamp
{
  # Print timestamp

  date -u "+%s.%N"  # Seconds + nanoseconds since 1970-01-01
}
function timestamp_diff
{
  # Print difference of timestamps, in seconds

# local start_s=$(("10#${1%.*}")) # older variants of bash do not support "10#" here
# local start_n=$(("10#${1#*.}"))
# local   end_s=$(("10#${2%.*}"))
# local   end_n=$(("10#${2#*.}"))

  local start_s=$(strip "${1%.*}")
  local start_n=$(strip "${1#*.}")
  local   end_s=$(strip "${2%.*}")
  local   end_n=$(strip "${2#*.}")

  if (( end_n < start_n ))
  then
    ((end_s -= 1))
    ((end_n += 1000000000))
  fi

  printf '%u.%09u\n' "$((end_s - start_s))" "$((end_n - start_n))"
}

function strip
{
  # Strip leading 0s so the number will not be interpreted as octal

  local i="$1"
  while (( ${#i} > 1 )) && [[ ${i:0:1} == "0" ]]
  do
    i=${i:1}
  done
  printf '%u\n' "$i"
}

function xml_escape
{
  local src="$1"
  local dest=""

  while (( ${#src} > 0 ))
  do
    local ch=${src:0:1}
    src=${src:1}

    if [[ $ch == '&' ]]
    then
      dest+="&amp;"
    elif [[ $ch == '<' ]]
    then
      dest+="&lt;"
    elif [[ $ch == '>' ]]
    then
      dest+="&gt;"
    elif [[ $ch == "'" ]]
    then
      dest+="&apos;"
    elif [[ $ch == '"' ]]
    then
      dest+="&quot;"
    else
      dest+="$ch"
    fi
  done

  printf '%s\n' "$dest"
}

# Test "caption package bundle"

disable test/floatrow/floatrow.dtx        # ! Arithmetic overflow.
disable test/floatrow/floatrow-rus.tex    # ! Arithmetic overflow.
disable test/floatrow/frsample04.tex      # Does not compile with pdflatex
disable test/floatrow/frsample10.tex      # Does not compile with pdflatex
disable test/floatrow/frsample11.tex      # Does not compile with pdflatex
disable test/floatrow/fr-sample.tex       # Interims file
disable test/floatrow/pictures.tex        # Interims file
disable test/floatrow/r-longtable.tex     # Interims file
disable test/floatrow/s-longtable.tex     # Interims file
disable test/newfloat/figurewithin-3.tex  # Intended to fail w/ error
disable test/keyfloat/dtxexample_cut.tex  # Interims file
disable test/keyfloat/testfloat_html.tex  # Interims file
disable test/ragged2e/ragged2e_4.tex      # Intended to fail w/ error
disable test/ragged2e/ragged2e_5.tex      # Intended to fail w/ error
disable issues/email/2009-09-29.tex       # Intended to fail w/ error (related to floatrow)
disable issues/usenet/2005-06-28-foo.tex  # Interims file
disable issues/usenet/2005-06-28-bar.tex  # Interims file
disable issues/usenet/2005-06-28-baz.tex  # Interims file
disable issues/other/2007-09-13.tex       # Intended to fail w/ error: labelsep=newline + \setcaphanging
disable issues/other/2012-09-21.tex       # Bug in fltpage
disable issues/other/2013-01-09.tex       # Bug in fltpage
disable issues/sourceforge/ticket_2.tex   # Bug in fltpage
disable issues/sourceforge/ticket_4.tex   # TODO: Adaption to hvfloat
disable issues/sourceforge/ticket_12.tex  # Can't compile tufte-book
disable issues/sourceforge/ticket_26.tex  # Bug in refcheck
disable issues/sourceforge/ticket_37.tex  # TODO: \iflistof
disable issues/sourceforge/ticket_40.tex  # Bug in catoptions
disable issues/sourceforge/ticket_43.tex  # Intended to fail w/ error: subcaption + subfig
disable issues/sourceforge/ticket_44.tex  # Intended to fail w/ error: \captionof{subfigure}
disable issues/sourceforge/ticket_47.tex  # TODO: \DeclareCaptionListHook
disable issues/gitlab/issue_25.tex        # Doomed to fail: \newsubfloat + subcaption package
disable issues/gitlab/issue_29.tex        # Needs Culmus fonts to compile
disable issues/gitlab/issue_35.tex        # Needs <whatever> to compile (greek & farsi)
disable issues/gitlab/issue_65.tex        # Doomed to fail: frontiers document class + subcaption package
disable unsorted                          # TODO

main "$@"

