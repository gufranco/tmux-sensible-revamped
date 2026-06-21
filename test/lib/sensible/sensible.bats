#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _SENSIBLE_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/sensible/sensible.sh"
}

teardown() {
  cleanup_test_environment
}

@test "sensible.sh - parse_tmux_version handles suffixes and prefixes" {
  [[ "$(parse_tmux_version 'tmux 3.4')" == "3.4" ]]
  [[ "$(parse_tmux_version 'tmux 3.4a')" == "3.4" ]]
  [[ "$(parse_tmux_version 'tmux next-3.5')" == "3.5" ]]
  [[ "$(parse_tmux_version 'tmux 1.9')" == "1.9" ]]
  [[ "$(parse_tmux_version 'tmux 2.9a')" == "2.9" ]]
}

@test "sensible.sh - version_ge compares correctly" {
  version_ge 3.4 3.2
  version_ge 3.2 3.2
  version_ge 1.9 1.6
  ! version_ge 3.1 3.2
  ! version_ge 2.9 3.0
  ! version_ge "" 3.2
}

@test "sensible.sh - truecolor_supported reads COLORTERM" {
  truecolor_supported truecolor
  truecolor_supported 24bit
  ! truecolor_supported 256
  ! truecolor_supported ""
}

@test "sensible.sh - os_kind classifies the host" {
  [[ "$(os_kind Darwin '')" == "darwin" ]]
  [[ "$(os_kind Linux 'Linux version 5.15 microsoft-standard-WSL2')" == "wsl" ]]
  [[ "$(os_kind Linux 'Linux version 6.1 generic')" == "linux" ]]
  [[ "$(os_kind FreeBSD '')" == "other" ]]
}

@test "sensible.sh - is_iterm detects iTerm2 via either signal" {
  is_iterm "iTerm.app" ""
  is_iterm "iTerm2" ""
  is_iterm "" "iTerm2"
  ! is_iterm "Apple_Terminal" ""
  ! is_iterm "" ""
}

@test "sensible.sh - editor_mode_keys maps vi family to vi" {
  [[ "$(editor_mode_keys nvim)" == "vi" ]]
  [[ "$(editor_mode_keys /usr/bin/vim)" == "vi" ]]
  [[ "$(editor_mode_keys vi)" == "vi" ]]
  [[ "$(editor_mode_keys emacs)" == "emacs" ]]
  [[ "$(editor_mode_keys '')" == "emacs" ]]
}

@test "sensible.sh - clipboard_command picks by priority" {
  _have() { [[ "$1" == "wl-copy" ]]; }
  [[ "$(clipboard_command wayland '' linux)" == "wl-copy" ]]
  _have() { [[ "$1" == "clip.exe" ]]; }
  [[ "$(clipboard_command '' '' wsl)" == "clip.exe" ]]
  _have() { [[ "$1" == "pbcopy" ]]; }
  [[ "$(clipboard_command '' '' darwin)" == "pbcopy" ]]
  _have() { [[ "$1" == "xclip" ]]; }
  [[ "$(clipboard_command '' :0 linux)" == "xclip -selection clipboard" ]]
  _have() { [[ "$1" == "xsel" ]]; }
  [[ "$(clipboard_command '' :0 linux)" == "xsel -ib" ]]
  _have() { return 1; }
  [[ -z "$(clipboard_command '' '' other)" ]]
}

@test "sensible.sh - clipboard_command falls through without a local tool" {
  _have() { return 1; }
  [[ -z "$(clipboard_command wayland :0 darwin)" ]]
}

@test "sensible.sh - default_terminal prefers tmux-256color when present" {
  _has_terminfo() { return 0; }
  [[ "$(default_terminal)" == "tmux-256color" ]]
  _has_terminfo() { return 1; }
  [[ "$(default_terminal)" == "screen-256color" ]]
}

@test "sensible.sh - current_os and tmux_version use the seams" {
  _uname() { echo "Darwin"; }
  _proc_version() { echo ""; }
  [[ "$(current_os)" == "darwin" ]]
  _tmux_version_string() { echo "tmux 3.3a"; }
  [[ "$(tmux_version)" == "3.3" ]]
}

@test "sensible.sh - resolve_clipboard composes os and env" {
  _uname() { echo "Linux"; }
  _proc_version() { echo "generic"; }
  _have() { [[ "$1" == "wl-copy" ]]; }
  WAYLAND_DISPLAY="wayland-0" DISPLAY="" run resolve_clipboard
  [[ "${output}" == "wl-copy" ]]
}

@test "sensible.sh - host-probe seams are callable" {
  run _tmux_version_string
  run _have ls
  run _uname
  run _proc_version
  run _has_terminfo xterm
  run _prefix
  run _get_server_option escape-time
  run _key_unbound R
  true
}
