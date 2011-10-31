# Author: Lital Natan <litaln@gmail.com>
# Bash enhancement, save last 10 directories and allow moving between them quickly
# modified CD command
# adds the -l flag - list saved directories
# cd -X  (x is numeric) change the directory no X
# 

if [[ -z $DIRH_HISTORY ]]; then
  DIRH_HISTORY=$PWD
fi

export DIRH_HISTORY
export DIRH_MAX_COUNT=10

dirh_append() {
  if [[ -z $DIRH_HISTORY ]]; then
    DIRH_HISTORY=$1
  else
    DIRH_HISTORY="$DIRH_HISTORY:$1"
  fi
  export DIRH_HISTORY
}

dirh_instr() {
  local str=$1
  local substr=$2
  local i
  local occurance
  occurance=$3
  local len
  let len=${#substr}
  [[ -z $occurance ]] && occurance=1
  for ((i=0 ; i < ${#str} ; i++ )); do
    if [[ ${str:$i:$len} == $substr ]]; then
      if [[ $occurance -lt 1 ]]; then
        echo -1
        return 
      fi
      if [[ $occurance -ne 1 ]]; then
        let occurance=$occurance-1
        continue
      fi
      echo $i
      return
    fi
  done
  echo -1
}

dirh_pop() {
  local pos
  let pos=$(dirh_instr $DIRH_HISTORY :)
  if [[ $pos -eq -1 ]]; then
    DIRH_HISTORY=""
    return
  fi
  let pos=$pos+1
  DIRH_HISTORY=${DIRH_HISTORY:$pos}
  export DIRH_HISTORY
}

dirh_get() {
  local dirn
  let dirn=$1
  let dcount=$(dirh_count $DIRH_HISTORY :)+1
  if [[ $dirn -gt $dcount ]]; then
    echo "No such bookmark" >> /dev/stderr
    return 1
  fi
  let e=$1-1
  let start=$(dirh_instr $DIRH_HISTORY : $e)+1
  let end=$(dirh_instr $DIRH_HISTORY : $dirn)
  if [[ $start -lt 0 ]]; then start=0; fi
  if [[ $end -eq -1 ]]; then
    echo ${DIRH_HISTORY:$start}
  else
    let length=$end-$start
    echo ${DIRH_HISTORY:$start:$length}
  fi
}

dirh_count() {
  local str=$1
  local substr=$2
  local i
  local occurances
  occurances=0
  for ((i=0 ; i < ${#str} ; i++ )); do
    if [[ ${str:$i:1} == $substr ]]; then
      let occurances=$occurances+1
    fi
  done
  echo $occurances
}

dirh_exists() {
  local dcount
  local dirpath=$1
  if [[ -z $DIRH_HISTORY ]]; then
    return 1
  fi
  let dcount=$(dirh_count $DIRH_HISTORY :)+1
  for ((i=1 ; i<=$dcount ; i++)); do
    if [[ $(dirh_get $i) == $dirpath ]]; then
      return 0
    fi
  done
  return 1
}

dirh_list() {
  echo $DIRH_HISTORY | tr ":" "\n" | cat -n
}

dirh_add() {
  local dirpath=$1
  [[ $(dirh_instr ":$DIRH_HISTORY:" ":$dirpath:") -ne -1 ]] && return
  dirh_append $dirpath
  let dcount=$(dirh_count $DIRH_HISTORY :)
  if [[ $dcount -gt $DIRH_MAX_COUNT ]]; then
    dirh_pop
  fi
}

cd() {
  local c=$1
  if [[ $c == "-l" ]]; then
    dirh_list
    return $?
  fi
  if [[ $c == "-c" ]]; then
    export DIRH_HISTORY=""
    return $?
  fi
  if [[ ${c} != "-" ]] && [[ ${c:0:1} == "-" ]] && [[ "$c" -lt 0 ]]; then
    let c=$c*-1
    NEXT_DIR=$(dirh_get $c)
    command cd $NEXT_DIR
    RET=$?
    [[ $RET -ne 0 ]] && return $RET
    echo -e "\033[31m${NEXT_DIR}"
    return 0
  fi
  command cd "$@"
  RET=$?
  [[ $RET -ne 0 ]] && return $RET
  dirh_add $PWD
}
