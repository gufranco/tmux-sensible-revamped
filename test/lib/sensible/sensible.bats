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

@test "sensible.sh - nested_term flags inner multiplexers" {
  nested_term screen
  nested_term screen-256color
  nested_term tmux-256color
  ! nested_term xterm-256color
  ! nested_term ""
}

@test "sensible.sh - should_truecolor honors COLORTERM" {
  _terminfo_rgb() { return 1; }
  should_truecolor truecolor xterm-256color
  should_truecolor 24bit xterm-256color
  ! should_truecolor "" xterm-256color
}

@test "sensible.sh - should_truecolor falls back to terminfo when COLORTERM is unset" {
  _terminfo_rgb() { return 0; }
  should_truecolor "" xterm-256color
  _terminfo_rgb() { return 1; }
  ! should_truecolor "" xterm-256color
}

@test "sensible.sh - should_truecolor never tags a nested terminal" {
  _terminfo_rgb() { return 0; }
  ! should_truecolor truecolor screen-256color
  ! should_truecolor "" tmux-256color
}

@test "sensible.sh - extended_keys_terminal recognizes capable terminals" {
  extended_keys_terminal xterm-256color ""
  extended_keys_terminal xterm-kitty ""
  extended_keys_terminal alacritty ""
  extended_keys_terminal st-256color ""
  extended_keys_terminal konsole-256color ""
  extended_keys_terminal "" iTerm.app
  extended_keys_terminal "" WezTerm
  extended_keys_terminal "" contour
  extended_keys_terminal "" rio
  ! extended_keys_terminal dumb ""
  ! extended_keys_terminal screen-256color "Apple_Terminal"
}

@test "sensible.sh - osc52_terminal recognizes clipboard-capable terminals" {
  osc52_terminal xterm-256color ""
  osc52_terminal foot ""
  osc52_terminal "" WezTerm
  osc52_terminal screen-256color ""
  ! osc52_terminal dumb ""
}

@test "sensible.sh - cursor_shape_terminal recognizes DECSCUSR terminals" {
  cursor_shape_terminal xterm-256color ""
  cursor_shape_terminal gnome-256color ""
  cursor_shape_terminal "" ghostty
  ! cursor_shape_terminal dumb ""
}

@test "sensible.sh - sixel_terminal recognizes sixel renderers" {
  sixel_terminal xterm-256color ""
  sixel_terminal foot ""
  sixel_terminal "" WezTerm
  sixel_terminal "" iTerm.app
  ! sixel_terminal alacritty ""
  ! sixel_terminal "" Apple_Terminal
}

@test "sensible.sh - hyperlink_terminal recognizes OSC 8 terminals" {
  hyperlink_terminal xterm-kitty ""
  hyperlink_terminal alacritty ""
  hyperlink_terminal "" WezTerm
  ! hyperlink_terminal dumb ""
  ! hyperlink_terminal "" Apple_Terminal
}

@test "sensible.sh - choose_default_terminal prefers direct then 256 then screen" {
  [[ "$(choose_default_terminal 1 1 1)" == "tmux-direct" ]]
  [[ "$(choose_default_terminal 1 0 1)" == "tmux-256color" ]]
  [[ "$(choose_default_terminal 0 1 1)" == "tmux-256color" ]]
  [[ "$(choose_default_terminal 0 0 0)" == "screen-256color" ]]
}

@test "sensible.sh - default_terminal_unset treats screen variants as unconfigured" {
  default_terminal_unset ""
  default_terminal_unset screen
  default_terminal_unset screen-256color
  ! default_terminal_unset tmux-256color
  ! default_terminal_unset rxvt-unicode-256color
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
  _have() { [[ "$1" == "termux-clipboard-set" ]]; }
  [[ "$(clipboard_command '' '' linux)" == "termux-clipboard-set" ]]
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

@test "sensible.sh - clipboard_command prefers X11 over clip.exe on WSLg" {
  _have() { [[ "$1" == "xclip" || "$1" == "clip.exe" ]]; }
  [[ "$(clipboard_command '' :0 wsl)" == "xclip -selection clipboard" ]]
}

@test "sensible.sh - clipboard_command falls through without a local tool" {
  _have() { return 1; }
  [[ -z "$(clipboard_command wayland :0 darwin)" ]]
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
  run _terminfo_rgb xterm
  run _prefix
  run _get_server_option escape-time
  run _get_window_option mode-keys
  run _key_unbound R
  true
}
