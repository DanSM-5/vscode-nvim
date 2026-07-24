#!/usr/bin/env bash

# Modified version of preview.sh on fzf.git to support powershell, bash (git) and zsh (git) 

REVERSE="\x1b[7m"
RESET="\x1b[m"

if [ -z "$1" ]; then
  echo "usage: $0 [--tag] FILENAME[:LINENO][:IGNORED]"
  exit 1
fi

# TODO: Handle tag preview?
if [ "$1" = --tag ]; then
  # shift
  # "$(dirname "${BASH_SOURCE[0]}")/tagpreview.sh" "$@"
  # exit $?
  exit 0
fi

IFS=':' read -r -a INPUT <<< "$1"

# FILE is absolute path
if [[ "${INPUT[0]}" =~ ^[A-Za-z]$ ]]; then
  FILE="${INPUT[0]}"           # drive letter e.g. 'C'
  FILE="/${FILE,,}${INPUT[1]}" # '/c' + filename
  CENTER="${INPUT[2]}"         # 'number'
else
  FILE="${INPUT[0]}"
  CENTER="${INPUT[1]}"
fi

# Ensure forward slash
FILE="$( sed -r 's/\\+/\//g' <<< "$FILE" )"

if [ -d "$FILE" ]; then
  printf "Path: $(realpath "$FILE" 2> /dev/null || printf '%s' "$FILE")\n\n"

  erd --layout inverted --color force --level 3 --suppress-size -I -- "$FILE" 2> /dev/null ||
    eza -A --tree --level=3 --color=always --icons=always --dereference "$FILE" 2> /dev/null ||
    ls -AFL --color=always "$FILE" 2> /dev/null ||
    printf '\nCannot access directory %s' "$FILE"

  exit
elif ! [ -r "$FILE" ]; then
  # echo "$TESTNAME"
  echo "File not found ${FILE}"
  exit 1
fi

if [ -z "$CENTER" ]; then
  CENTER=0
fi

# Sometimes bat is installed as batcat.
if command -v batcat > /dev/null; then
  BATNAME="batcat"
elif command -v bat > /dev/null; then
  BATNAME="bat"
fi

if [ -z "$FZF_PREVIEW_COMMAND" ] && [ "${BATNAME:+x}" ]; then
  ${BATNAME} --style="${BAT_STYLE:-numbers}" --color=always --pager=never \
      --highlight-line="$CENTER" -- "$FILE"
  exit $?
fi

FILE_LENGTH=${#FILE}
MIME=$(file --dereference --mime -- "$FILE")
if [[ "${MIME:FILE_LENGTH}" =~ binary ]]; then
  echo "$MIME"
  exit 0
fi

DEFAULT_COMMAND="highlight -O ansi -l {} || coderay {} || rougify {} || cat {}"
CMD=${FZF_PREVIEW_COMMAND:-$DEFAULT_COMMAND}
CMD=${CMD//{\}/$(printf %q "$FILE")}

eval "$CMD" 2> /dev/null | awk "{ \
    if (NR == $CENTER) \
        { gsub(/\x1b[[0-9;]*m/, \"&$REVERSE\"); printf(\"$REVERSE%s\n$RESET\", \$0); } \
    else printf(\"$RESET%s\n\", \$0); \
    }"
