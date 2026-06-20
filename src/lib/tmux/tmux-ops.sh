#!/usr/bin/env bash
#
# tmux-ops.sh: thin wrappers over tmux option get/set.
#
# Every plugin in the family reads and writes its state through these helpers.
# The cache layer builds on top of them, which is why all runtime state lives in
# tmux server user-options and never in temp files.

[[ -n "${_TMUX_PLUGIN_TMUX_OPS_LOADED:-}" ]] && return 0
_TMUX_PLUGIN_TMUX_OPS_LOADED=1

# get_tmux_option OPTION [DEFAULT] -> the global option value, or DEFAULT if unset.
get_tmux_option() {
  local option="${1}"
  local default="${2:-}"
  local value
  value=$(tmux show-option -gqv "${option}" 2>/dev/null)
  [[ -z "${value}" ]] && echo "${default}" || echo "${value}"
}

# set_tmux_option OPTION VALUE -> store a global option.
set_tmux_option() {
  tmux set-option -gq "${1}" "${2}" 2>/dev/null
}

# unset_tmux_option OPTION -> remove a global option.
unset_tmux_option() {
  tmux set-option -gqu "${1}" 2>/dev/null
}

export -f get_tmux_option
export -f set_tmux_option
export -f unset_tmux_option
