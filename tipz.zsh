#!/usr/bin/env zsh

###
# Search the defined aliases for a match
###
function _tipz_find_match() {
  local bits alias command result=""
  local -a aliases args; args="$@"

  # Load the current aliases into an array
  local oldIFS=$IFS
  IFS=$'\n' aliases=($(alias))
  IFS=$oldIFS
  unset oldIFS

  # Loop through each of the aliases
  for line in "$aliases[@]"; do
    # Split the line on '=' to separate the command
    # and its alias
    bits=("${(s/=/)line}")
    alias=$bits[1]
    command=$bits[2]

    # Create a regex that finds an exact match for
    # the current argument string
    args="${(@)args[@]}"
    local pattern=$'^[\'\"]?'${args//([^a-zA-Z0-9])/\\$1}$'[\'\"]?$'

    # Check if the command matches the regex
    if [[ "$command" =~ $pattern ]]; then
      # Ensure that the longest matching command is stored
      if [[ ${#command} > ${#result} ]]; then
        result=$alias
      fi
    fi
  done

  # If a result has been found, output it
  if [[ -n $result ]]; then
    echo $result
    return 0
  fi

  return 1
}

###
# Search for alias tips for the currently executing command
###
function _tipz_process {
  local -a cmd; cmd=($@)
  integer i=${#cmd}

  # Loop for the length of the argument list, knocking
  # an argument from the end of the list each time, and
  # then using the remaining arguments to search for aliases
  while [[ $i > 0 ]]; do
    # Check the current string for a match
    result=$(_tipz_find_match "${(@)cmd:0:$i}")

    # If the search exited successfully,
    # output the tip to the user
    if [[ $? -eq 0 ]]; then
      echo "\033[1;34m${ZSH_PLUGINS_TIPZ_TEXT:-Tipz:}\033[0;m \033[0;34m$result ${(@)cmd:$i}\033[0;m"
      return 0
    fi

    # Decrement the counter
    i=$(( i - 1 ))
  done

  return 1
}

###
# A small function to filter out strange arguments
# sent from the add-zsh-hook preexec hook
###
function _tipz_prexec() {
  _tipz_process $(echo $1)
}

###
# Register the preexec hook
###
autoload -Uz add-zsh-hook
add-zsh-hook preexec _tipz_prexec
