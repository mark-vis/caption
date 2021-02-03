#!/bin/bash

# Module: test-lib.sh
# Author: Axel Sommerfeldt (axel.sommerfeldt@f-m.fm)
# URL:    https://gitlab.com/axelsommerfeldt/caption
# Date:   2021-02-03

# shellcheck disable=SC2155
#   disables the warning "Declare and assign separately to avoid masking return values."

basedir=$(pwd)

all=true                 # default: Target "all"
disabled_pdflatex=()     # default: Compile all testcases (pdflatex engine)
disabled_xelatex=()      # default: Compile all testcases (xelatex engine)
disabled_lualatex=()     # default: Compile all testcases (lualatex engine)
disabled_htlatex=()      # default: Compile all testcases (htlatex engine)
exit_on_error=true       # default: Exit after error
interactive=true         # default: Interactive mode
output_file=""           # default: Don't generate report file
latex_engine="pdflatex"  # default: Use pdflatex
latex_suffix=""          # default: Use regular version of latex

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
      printf "Usage: ./test.sh [OPTIONS]... [all|clean|DIRECTORY|FILE]...\n"
      printf "\n"
      printf "  -d, --disable=FILE      doesn't compile FILE (or DIRECTORY)\n"
      printf "  -i, --interactive=BOOL  sets interactive mode (default:true)\n"
      printf "  -o, --output=FILE       generates a report file\n"
      printf "      --pdflatex          uses pdflatex as LaTeX engine (default)\n"
      printf "      --xelatex           uses xelatex as LaTeX engine\n"
      printf "      --lualatex          uses lualatex as LaTeX engine\n"
      printf "      --htlatex           uses htlatex as LaTeX engine\n"
      printf "      --dev               uses the current development version of LaTeX\n"
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
    elif [[ $arg == "--pdflatex" ]]
    then
      latex_engine="pdflatex"
    elif [[ $arg == "--xelatex" ]]
    then
      latex_engine="xelatex"
    elif [[ $arg == "--lualatex" ]]
    then
      latex_engine="lualatex"
    elif [[ $arg == "--htlatex" ]]
    then
      latex_engine="htlatex"
    elif [[ $arg == "--dev" ]]
    then
      latex_suffix="-dev"
    elif [[ ${arg:0:1} == "-" ]]
    then
      printf "*** Invalid option '%s'.\n" "$arg" >&2
      exit 1
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
        printf "*** Invalid argument '%s'.\n" "$arg" >&2
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

  # Print test summary
  if (( gl_tests > 1 ))
  then
    printf '\ntests=%d, failures=%d, disabled=%d, time=%ss\n' "$gl_tests" "$gl_failures" "$gl_disabled" "$(timestamp_diff "$gl_start" "$gl_end")"
  fi

  # Generate report file, if requested
  # Note: GitLab CI does not care about "testsuites" or "testsuite" elements, it only evaluates "testcase" elements.
  # The "classname" attribute will be displayed as "Suite", the "name" attribute as "Name", and the "time" as "Duration".
  # The combination of "classname" and "name" must be unique, otherwise the "testcase" elements will not be counted as
  # different tests. If the "testcase" contains a "failure" element it will be counted as "Failed", if it contains an
  # "error" element it will be counted as "Error", if it contains a "skipped" element is will be counted as "Skipped",
  # and all other "testcase" elements will be counted as "Passed".
  # See also: https://docs.gitlab.com/ee/ci/unit_test_reports.html
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
      is_disabled "$dir" "$file" || compile_dir_file "$dir" "$file"
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
  copy_package_files
}

function copy_package_files
{
  cp -a "$basedir"/tex/*.sty "$basedir"/tex/*.sto .
}

function post_compile_files
{
  # Generate report
  local temp
  printf -v temp '<testsuite name=\"%s\" tests=\"%d\" failures=\"%d\" disabled=\"%d\" time=\"%s\">\n%s</testsuite>\n' "$dir" "$tests" "$failures" "$disabled" "$(timestamp_diff "$start" "$end")" "$content"
  gl_content+="$temp"

  # Update global counters
  (( gl_tests += tests ))
  (( gl_failures += failures ))
  (( gl_disabled += disabled ))
}

function compile_dir_file
{
  # Compile a single file as "testcase" as part of a "testsuite"

  ((++tests))

  local start=$(timestamp)
  compile "$2"
  local result=$?
  local end=$(timestamp)

  local temp
  if (( result == 0 ))
  then
    printf "Compiling %s/%s passed.\n" "$1" "$2"
    printf -v temp '<testcase classname="%s" name="%s" time="%s" />\n' "$1" "$2" "$(timestamp_diff "$start" "$end")"
  else
    printf "\n*** Compiling %s/%s failed.\n" "$1" "$2"
    printf -v temp '<testcase classname="%s" name="%s" time="%s"><failure message="%s" type="ERROR" /></testcase>\n' "$1" "$2" "$(timestamp_diff "$start" "$end")" "$(xml_escape "$message")"

    ((++failures))

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

  # shellcheck disable=SC2034  # disable warning that <i> isn't used
  for i in {1..3}
  do
    local result log

    if $interactive
    then
      log=""
      $latex_engine$latex_suffix "$1"
      result=$?
    else
#     sleep 0.1
      log=$($latex_engine$latex_suffix -halt-on-error "$1")
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
    printf "*** Invalid boolean value '%s'.\n" "$1" >&2
    exit 1
  fi
}

function disable
{
  # Disable test-suites or test-cases

  local all=true  # default: disable tests for all LaTeX engines
  local pdflatex=false
  local xelatex=false
  local lualatex=false
  local htlatex=false

  local arg
  for arg in "$@"
  do
    if [[ $arg == "--pdflatex" ]]
    then
      all=false
      pdflatex=true
    elif [[ $arg == "--xelatex" ]]
    then
      all=false
      xelatex=true
    elif [[ $arg == "--lualatex" ]]
    then
      all=false
      lualatex=true
    elif [[ $arg == "--htlatex" ]]
    then
      all=false
      htlatex=true
    elif [[ ${arg:0:1} == "-" ]]
    then
      printf "*** Invalid option '%s'.\n" "$arg" >&2
      exit 1
    else
      if $all || $pdflatex
      then
#       printf "Disable pdflatex: %s\n" "$arg"
        disabled_pdflatex+=( "$arg" )
      fi
      if $all || $xelatex
      then
#       printf "Disable xelatex: %s\n" "$arg"
        disabled_xelatex+=( "$arg" )
      fi
      if $all || $lualatex
      then
#       printf "Disable lualatex: %s\n" "$arg"
        disabled_lualatex+=( "$arg" )
      fi
      if $all || $htlatex
      then
#       printf "Disable htlatex: %s\n" "$arg"
        disabled_htlatex+=( "$arg" )
      fi
    fi
  done
}

function is_disabled
{
  # Test if the given testsuite or testcase is disabled

  local path="$1"
  if [[ -n $2 ]]; then path+="/$2"; fi

  local -a disabled_cases
  if [[ $latex_engine == "pdflatex" ]]
  then
    disabled_cases=( "${disabled_pdflatex[@]}" )
  elif [[ $latex_engine == "xelatex" ]]
  then
    disabled_cases=( "${disabled_xelatex[@]}" )
  elif [[ $latex_engine == "lualatex" ]]
  then
    disabled_cases=( "${disabled_lualatex[@]}" )
  elif [[ $latex_engine == "htlatex" ]]
  then
    disabled_cases=( "${disabled_htlatex[@]}" )
  else
    printf "*** Unknown LaTeX engine '%s'.\n" "$latex_engine" >&2
    exit 1
  fi

  local d
  for d in "${disabled_cases[@]}"
  do
    if [[ $d == "$path" ]]
    then

      # If a file (=testcase) is disabled, create an entry in the report file
      # See also: https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/ci/parsers/test/junit_spec.rb
      if [[ -n $2 ]]
      then
        ((++tests))
        ((++disabled))

        printf "* Compiling %s/%s skipped.\n" "$1" "$2"
        printf -v temp '<testcase classname="%s" name="%s" time="%s"><skipped/></testcase>\n' "$1" "$2" "0.0"
        content+="$temp"
      fi

      # Directory resp. file is disabled
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

