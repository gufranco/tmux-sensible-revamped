#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../../src/lib/tmux/tmux-ops.sh"
}

teardown() {
  cleanup_test_environment
}

@test "tmux-ops.sh - functions are defined" {
  function_exists get_tmux_option
  function_exists set_tmux_option
  function_exists unset_tmux_option
}

@test "tmux-ops.sh - get_tmux_option returns the default when unset" {
  [[ "$(get_tmux_option @nope fallback)" == "fallback" ]]
}

@test "tmux-ops.sh - get_tmux_option returns empty when no default is given" {
  [[ -z "$(get_tmux_option @missing)" ]]
}

@test "tmux-ops.sh - set then get round-trips the value" {
  set_tmux_option @foo bar
  [[ "$(get_tmux_option @foo)" == "bar" ]]
}

@test "tmux-ops.sh - a stored value overrides the default" {
  set_tmux_option @foo bar
  [[ "$(get_tmux_option @foo other)" == "bar" ]]
}

@test "tmux-ops.sh - unset removes the option" {
  set_tmux_option @foo bar
  unset_tmux_option @foo
  [[ -z "$(get_tmux_option @foo)" ]]
}
