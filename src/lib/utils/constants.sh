#!/usr/bin/env bash
# shellcheck disable=SC2034  # constants are sourced and read by other modules
#
# constants.sh: values shared by every plugin built from this template.
# Per-metric option names and thresholds live in each plugin's own constants.

[[ -n "${_TMUX_PLUGIN_CONSTANTS_LOADED:-}" ]] && return 0
_TMUX_PLUGIN_CONSTANTS_LOADED=1

# Version of the shared template these plugins are stamped from.
readonly TMUX_PLUGIN_TEMPLATE_VERSION="1.0.0"

# Default seconds a cached value stays fresh before a background refresh fires.
# Plugins override per metric: weather is minutes, cpu is a few seconds.
readonly TMUX_PLUGIN_DEFAULT_MAX_AGE="5"

# Sentinel printed while a value has not been computed yet (cold start).
readonly TMUX_PLUGIN_PENDING="..."
