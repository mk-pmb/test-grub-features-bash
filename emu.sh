#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function grub_emu_run_files () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  [ "$#" -ge 1 ] || return 4$(echo "E: no input files given!" >&2)

  local FIRST_INPUT_FILE="$1"; shift
  verify_first_input_file || return $?
  local LOGFN="$FIRST_INPUT_FILE"
  LOGFN="${LOGFN%.txt}"
  LOGFN="$LOGFN.log"

  ( LANG=C sed -nurf <(echo '
      /^# -\*- /{n;b skip_blanks}
      b mostly_copy

      : skip_blanks
        /./b mostly_copy
        n
      b skip_blanks

      : mostly_copy
      s~^\xEF\xBB\xBF~~
      p
    ') -- "$FIRST_INPUT_FILE" "$@"
    echo exit
  ) | DISPLAY= grub-emu --directory="$SELFPATH" |& LANG=C sed -urf <(echo '
    s~\x1B\[[0-9;]*[A-Za-z]~~g
    s~^\r~~
    s~^(grub> ) +~\1~
    ') | sed -nurf <(echo '
    1{
      : skip_intro
      /\n\n$/!{N;b skip_intro}
      b
    }
    /^grub> $/b
    /^grub> exit$/q
    p
    ') | tee -- "$LOGFN"
    git add -- "$LOGFN"
}


function verify_first_input_file () {
  local ORIG="$FIRST_INPUT_FILE"
  [ -f "$ORIG" ] && return 0

  local MAYBE=
  for MAYBE in "${ORIG%.}"{,.txt}; do
    [ -f "$MAYBE" ] || continue
    FIRST_INPUT_FILE="$MAYBE"
    return 0
  done

  echo "E: input file is not a file: $ORIG" >&2
  return 4
}





















grub_emu_run_files "$@"; exit $?
