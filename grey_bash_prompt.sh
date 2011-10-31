#!/bin/bash
# Author: Lital Natan <litaln@gmail.com>
# Description: Colorful, dual-lined bash prompt with git integration

BAR_COLOR="\[\033[0;34m\]"
BRACKET_COLOR="\[\033[1;34m\]"
TEXT_COLOR="\[\033[0;1m\]"
DIRECTORY_COLOR=$TEXT_COLOR
PROMPT_COLOR="\[\033[m\]"
DEFAULT_COLOR="\[\033[m\]"
MAX_PROMPT_DIR_LENGTH=45
WARNING_COLOR="\[\033[1;31m\]"
GIT_COMMITED_COLOR="\[\033[1;32m\]"
GIT_DIRTY_COLOR="\[\033[1;31m\]"

PROMPT_SIGN="#"

PADDING="~"

prompt_cmd() {
  LAST_RET=$?
  LAST_ARG=$_
  local GIT_BRANCH_NAME
  local GIT_STATUS
  local GIT_BRANCH
  local GIT_COLOR
  local CWD


  NONE="\[\033[0m\]"
  PROMPT_LENGTH=0
  PROMPT="${BRACKET_COLOR}(${TEXT_COLOR}${USER}${BRACKET_COLOR}@${TEXT_COLOR}${HOSTNAME}${BRACKET_COLOR})${BAR_COLOR}"
  for ((i=0; i<3; i++)); do
    PROMPT="${PROMPT}$PADDING"
  done
  let LAST_RET_LENGTH=4+${#LAST_RET}
  PROMPT="${PROMPT}${BRACKET_COLOR}[${TEXT_COLOR}R:"
  RET_COLOR=$TEXT_COLOR
  if [[ $LAST_RET -ne 0 ]]; then
    RET_COLOR="$WARNING_COLOR"
  fi
  PROMPT="${PROMPT}${RET_COLOR}${LAST_RET}${BRACKET_COLOR}]"
  let PROMPT_LENGTH=${#USER}+${#HOSTNAME}+3+3

  CWD=$PWD
  [[ $CWD == $HOME ]] && CWD="~"
  
  if [[ ${#CWD} -gt $MAX_PROMPT_DIR_LENGTH ]]; then
    let DIRLEN=$MAX_PROMPT_DIR_LENGTH-3
    STRIPPED_DIR="..."${CWD: -$DIRLEN}
  else
    STRIPPED_DIR=$CWD
  fi


  # Git branch
  GIT_BRANCH_LEN=0
  GIT_COLOR=$GIT_DIRTY_COLOR
  if [ -z "$NO_PROMPT_GIT" ]; then
      GIT_BRANCH_NAME=$(git branch 2>&1 | grep -- '*' | cut -d' ' -f2-)
      if [[ -n $GIT_BRANCH_NAME ]]; then
        let GIT_BRANCH_LEN=${#GIT_BRANCH_NAME}+2
        if git status 2> /dev/null | grep -q "nothing to commit"; then
          GIT_COLOR=$GIT_COMMITED_COLOR
        fi
        GIT_BRANCH="${BRACKET_COLOR}[${GIT_COLOR}$GIT_BRANCH_NAME${BRACKET_COLOR}]"
      fi
  else
      GIT_BRANCH_LEN=2
      GIT_BRANCH_NAME=""
      GIT_BRANCH="${BRACKET_COLOR}[${GIT_COLOR}$GIT_BRANCH_NAME${BRACKET_COLOR}]"
  fi

  DIRECTORY="${BRACKET_COLOR}[${DIRECTORY_COLOR}${STRIPPED_DIR}${BRACKET_COLOR}]"
  let DIRECTORY_LENGTH=${#STRIPPED_DIR}+2
  let BAR_LENGTH=${COLUMNS}-$PROMPT_LENGTH-$DIRECTORY_LENGTH-1-$LAST_RET_LENGTH-$GIT_BRANCH_LEN
  if test $BAR_LENGTH -lt 5; then
    PS1="$PROMPT \W#${NONE} "
    return
  fi
  BAR="$BAR_COLOR"
  for ((i=0; i<$BAR_LENGTH; i++)); do
    BAR="${BAR}$PADDING"
  done
  
  PS1="$DIRECTORY$BAR$PROMPT$GIT_BRANCH${BAR_COLOR}$PADDING$DEFAULT_COLOR${NONE}\r\n$PROMPT_COLOR\$ ${NONE}"
  _=$LAST_ARG
}

export PROMPT_COMMAND=prompt_cmd
