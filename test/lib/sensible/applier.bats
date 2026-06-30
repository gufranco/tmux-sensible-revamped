#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _SENSIBLE_REVAMPED_LOADED
  export SENSIBLE_DRY_RUN=1
  source "${BATS_TEST_DIRNAME}/../../../src/sensible.sh"
  _tmux_version_string() { echo "tmux 3.5"; }
  _get_option() { echo ""; }
  _have() { return 1; }
  _uname() { echo "Linux"; }
  _proc_version() { echo "generic"; }
  _has_terminfo() { return 0; }
  _terminfo_rgb() { return 1; }
  _prefix() { echo "C-b"; }
  _key_unbound() { return 0; }
  _get_server_option() { echo ""; }
  _get_window_option() { echo ""; }
  export EDITOR="" VISUAL="" COLORTERM="truecolor" TERM_PROGRAM="" LC_TERMINAL="" TERM="xterm-256color"
  export WAYLAND_DISPLAY="" DISPLAY="" XDG_CONFIG_HOME=""
  export HOME="${TEST_TMPDIR}"
}

teardown() {
  cleanup_test_environment
}

@test "applier - modern tmux 3.5 enables the full feature set" {
  run apply_sensible
  [[ "${output}" == *"set -as terminal-features ,*:RGB"* ]]
  [[ "${output}" == *"set -as terminal-features ,*:clipboard:ccolour:cstyle:focus:title"* ]]
  [[ "${output}" == *"set -as terminal-features ,rxvt*:ignorefkeys"* ]]
  [[ "${output}" == *"set -g allow-passthrough all"* ]]
  [[ "${output}" == *"set -as terminal-features ,*:sixel"* ]]
  [[ "${output}" == *"set -s extended-keys on"* ]]
  [[ "${output}" == *"set -s extended-keys-format csi-u"* ]]
  [[ "${output}" == *"set -sg escape-time 10"* ]]
  [[ "${output}" == *"set -g focus-events on"* ]]
  [[ "${output}" == *"set -g set-clipboard on"* ]]
  [[ "${output}" == *"set -g set-titles on"* ]]
  [[ "${output}" == *"set -g display-panes-time 2000"* ]]
  [[ "${output}" == *"setw -g pane-base-index 1"* ]]
  [[ "${output}" == *"set -g renumber-windows on"* ]]
}

@test "applier - tmux 1.9 skips features above its version" {
  _tmux_version_string() { echo "tmux 1.9"; }
  run apply_sensible
  [[ "${output}" != *"terminal-features"* ]]
  [[ "${output}" != *"allow-passthrough"* ]]
  [[ "${output}" != *"extended-keys"* ]]
  [[ "${output}" != *"Smulx"* ]]
  [[ "${output}" != *":sixel"* ]]
  [[ "${output}" == *"set -sg escape-time 10"* ]]
  [[ "${output}" == *"set -g focus-events on"* ]]
  [[ "${output}" == *"setw -g pane-base-index 1"* ]]
  [[ "${output}" == *"set -g renumber-windows on"* ]]
}

@test "applier - legacy truecolor override on old tmux with a truecolor terminal" {
  _tmux_version_string() { echo "tmux 2.8"; }
  export COLORTERM="truecolor"
  run apply_sensible
  [[ "${output}" == *"set -ga terminal-overrides ,*:Tc"* ]]
  [[ "${output}" != *"terminal-features ,*:RGB"* ]]
}

@test "applier - truecolor is not forced without COLORTERM or terminfo" {
  export COLORTERM=""
  _terminfo_rgb() { return 1; }
  run apply_sensible
  [[ "${output}" != *":RGB"* ]]
  [[ "${output}" != *":Tc"* ]]
}

@test "applier - truecolor falls back to terminfo when COLORTERM is unset" {
  export COLORTERM=""
  _terminfo_rgb() { return 0; }
  run apply_sensible
  [[ "${output}" == *"set -as terminal-features ,*:RGB"* ]]
}

@test "applier - nested screen TERM is never tagged truecolor" {
  export COLORTERM="truecolor" TERM="screen-256color"
  run apply_sensible
  [[ "${output}" != *":RGB"* ]]
  [[ "${output}" != *":Tc"* ]]
}

@test "applier - undercurl override appears on tmux 3.0 and up" {
  _tmux_version_string() { echo "tmux 3.0"; }
  run apply_sensible
  [[ "${output}" == *"Smulx"* ]]
}

@test "applier - OSC 52 and cursor-shape overrides appear below tmux 3.2" {
  _tmux_version_string() { echo "tmux 3.0"; }
  export TERM="xterm-256color"
  run apply_sensible
  [[ "${output}" == *"Ms=\\E]52"* ]]
  [[ "${output}" == *"Ss=\\E["* ]]
}

@test "applier - OSC 52 override is skipped on tmux 3.2 and up" {
  run apply_sensible
  [[ "${output}" != *"Ms=\\E]52"* ]]
  [[ "${output}" != *"Ss=\\E["* ]]
}

@test "applier - OSC 52 override is skipped on incapable terminals below 3.2" {
  _tmux_version_string() { echo "tmux 3.0"; }
  export TERM="dumb" TERM_PROGRAM=""
  run apply_sensible
  [[ "${output}" != *"Ms="* ]]
  [[ "${output}" != *"Ss="* ]]
}

@test "applier - allow-passthrough is on (not all) on tmux 3.3" {
  _tmux_version_string() { echo "tmux 3.3" ; }
  run apply_sensible
  [[ "${output}" == *"set -g allow-passthrough on"* ]]
  [[ "${output}" != *"allow-passthrough all"* ]]
}

@test "applier - allow-passthrough respects an explicit user value" {
  _get_option() { case "$1" in allow-passthrough) echo "on" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"allow-passthrough all"* ]]
}

@test "applier - hyperlinks feature appears on a capable terminal on 3.4+" {
  export TERM="xterm-kitty"
  run apply_sensible
  [[ "${output}" == *"set -as terminal-features ,*:hyperlinks"* ]]
}

@test "applier - default-terminal prefers tmux-direct with truecolor and terminfo" {
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal tmux-direct"* ]]
}

@test "applier - default-terminal falls back to tmux-256color without direct terminfo" {
  _has_terminfo() { [[ "$1" == "tmux-256color" ]]; }
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal tmux-256color"* ]]
}

@test "applier - default-terminal falls back to screen-256color without terminfo" {
  _has_terminfo() { return 1; }
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal screen-256color"* ]]
}

@test "applier - default-terminal upgrades a screen-256color value" {
  _get_option() { case "$1" in default-terminal) echo "screen-256color" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal tmux-direct"* ]]
}

@test "applier - default-terminal respects an explicit non-default value" {
  _get_option() { case "$1" in default-terminal) echo "rxvt-unicode-256color" ;; *) echo "" ;; esac; }
  _get_server_option() { case "$1" in default-terminal) echo "rxvt-unicode-256color" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g default-terminal"* ]]
  [[ "${output}" != *"set -sg default-terminal"* ]]
}

@test "applier - extended-keys is skipped on unsupporting terminals" {
  export TERM="dumb" TERM_PROGRAM=""
  run apply_sensible
  [[ "${output}" != *"extended-keys"* ]]
}

@test "applier - extended-keys is enabled on a broadened terminal" {
  export TERM="alacritty" TERM_PROGRAM=""
  run apply_sensible
  [[ "${output}" == *"set -s extended-keys on"* ]]
}

@test "applier - aggressive-resize on tmux 3.0+ is a control-mode hook" {
  export TERM_PROGRAM="iTerm.app"
  run apply_sensible
  [[ "${output}" == *"set-hook -g client-attached[1000]"* ]]
  [[ "${output}" == *"client_control_mode"* ]]
  [[ "${output}" == *"aggressive-resize off"* ]]
  [[ "${output}" == *"aggressive-resize on"* ]]
}

@test "applier - older tmux sets aggressive-resize on outside iTerm2" {
  _tmux_version_string() { echo "tmux 2.9"; }
  run apply_sensible
  [[ "${output}" == *"aggressive-resize on"* ]]
  [[ "${output}" != *"client-attached"* ]]
}

@test "applier - explicit user configuration is respected" {
  _get_option() { case "$1" in history-limit) echo "9999" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g history-limit 50000"* ]]
  [[ "${output}" == *"set -g status-interval 5"* ]]
}

@test "applier - set-clipboard respects an explicit user value" {
  _get_option() { case "$1" in set-clipboard) echo "off" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g set-clipboard on"* ]]
}

@test "applier - focus-events respects an explicit user value" {
  _get_option() { case "$1" in focus-events) echo "off" ;; *) echo "" ;; esac; }
  _get_option() { case "$1" in focus-events) echo "on" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g focus-events on"* ]]
}

@test "applier - status-keys respects an explicit vi value" {
  _get_option() { case "$1" in status-keys) echo "vi" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g status-keys"* ]]
}

@test "applier - set-titles respects an explicit user value" {
  _get_option() { case "$1" in set-titles) echo "off" ;; *) echo "" ;; esac; }
  _get_option() { case "$1" in set-titles) echo "off-but-changed" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g set-titles on"* ]]
}

@test "applier - word-separators is narrowed for clean path selection" {
  run apply_sensible
  [[ "${output}" == *"setw -g word-separators"* ]]
}

@test "applier - copy bindings use the resolved clipboard command" {
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "pbcopy" ]]; }
  run apply_sensible
  [[ "${output}" == *"copy-pipe-and-cancel pbcopy"* ]]
}

@test "applier - copy bindings fall back to OSC52 without a tool" {
  _have() { return 1; }
  run apply_sensible
  [[ "${output}" == *"copy-selection-and-cancel"* ]]
  [[ "${output}" != *"copy-pipe-and-cancel"* ]]
}

@test "applier - vi selection keys are bound on tmux 2.4+" {
  run apply_sensible
  [[ "${output}" == *"bind-key -T copy-mode-vi v send-keys -X begin-selection"* ]]
  [[ "${output}" == *"bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle"* ]]
  [[ "${output}" == *"bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel"* ]]
}

@test "applier - copy bindings use legacy tables below tmux 2.4" {
  _tmux_version_string() { echo "tmux 2.3"; }
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "pbcopy" ]]; }
  run apply_sensible
  [[ "${output}" == *"bind-key -t vi-copy y copy-pipe pbcopy"* ]]
  [[ "${output}" == *"bind-key -t emacs-copy M-w copy-pipe pbcopy"* ]]
  [[ "${output}" == *"bind-key -t vi-copy v begin-selection"* ]]
  [[ "${output}" != *"copy-pipe-and-cancel"* ]]
}

@test "applier - legacy copy bindings fall back without a tool below 2.4" {
  _tmux_version_string() { echo "tmux 2.3"; }
  _have() { return 1; }
  run apply_sensible
  [[ "${output}" == *"bind-key -t vi-copy y copy-selection"* ]]
  [[ "${output}" == *"bind-key -t emacs-copy M-w copy-selection"* ]]
}

@test "applier - mode-keys follows the editor" {
  export EDITOR="nvim"
  run apply_sensible
  [[ "${output}" == *"mode-keys vi"* ]]
}

@test "applier - mode-keys respects an explicit user choice" {
  export EDITOR=""
  _get_window_option() { case "$1" in mode-keys) echo "vi" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"mode-keys"* ]]
}

@test "applier - opinionated noisy options are not forced" {
  run apply_sensible
  [[ "${output}" != *"monitor-activity"* ]]
  [[ "${output}" != *"set -g mouse"* ]]
}

@test "applier - macos reattach wrapper only when the helper is present" {
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "reattach-to-user-namespace" ]]; }
  run apply_sensible
  [[ "${output}" == *"reattach-to-user-namespace -l \$SHELL"* ]]
}

@test "applier - reload binding is emitted when R is free" {
  run apply_sensible
  [[ "${output}" == *"bind-key R source-file"* ]]
}

@test "applier - binds window navigation when unbound" {
  run apply_sensible
  [[ "${output}" == *"bind-key b last-window"* ]]
  [[ "${output}" == *"bind-key C-p previous-window"* ]]
  [[ "${output}" == *"bind-key C-n next-window"* ]]
}

@test "applier - binds send-prefix for a custom prefix" {
  _prefix() { echo "C-a"; }
  run apply_sensible
  [[ "${output}" == *"unbind-key C-b"* ]]
  [[ "${output}" == *"bind-key C-a send-prefix"* ]]
  [[ "${output}" == *"bind-key a last-window"* ]]
}

@test "applier - existing user bindings are respected" {
  _key_unbound() { return 1; }
  run apply_sensible
  [[ "${output}" != *"bind-key C-p"* ]]
  [[ "${output}" != *"bind-key C-n"* ]]
  [[ "${output}" != *"bind-key R source-file"* ]]
}

@test "applier - escape-time respects an explicit user value" {
  _get_server_option() { case "$1" in escape-time) echo "100" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"escape-time 10"* ]]
}

@test "applier - older tmux skips aggressive-resize under iTerm2 via LC_TERMINAL" {
  _tmux_version_string() { echo "tmux 2.9"; }
  export LC_TERMINAL="iTerm2"
  run apply_sensible
  [[ "${output}" != *"aggressive-resize"* ]]
}

@test "applier - _emit runs tmux outside dry-run mode" {
  unset SENSIBLE_DRY_RUN
  tmux set-option -gq "@probe" "value123"
  run _emit show-option -gqv "@probe"
  [[ "${output}" == "value123" ]]
}

@test "applier - config path honors XDG_CONFIG_HOME" {
  mkdir -p "${TEST_TMPDIR}/xdg/tmux"
  : > "${TEST_TMPDIR}/xdg/tmux/tmux.conf"
  export XDG_CONFIG_HOME="${TEST_TMPDIR}/xdg"
  [[ "$(_config_path)" == "${TEST_TMPDIR}/xdg/tmux/tmux.conf" ]]
}

@test "applier - config path falls back to ~/.config then ~/.tmux.conf" {
  export XDG_CONFIG_HOME=""
  export HOME="${TEST_TMPDIR}"
  mkdir -p "${TEST_TMPDIR}/.config/tmux"
  : > "${TEST_TMPDIR}/.config/tmux/tmux.conf"
  [[ "$(_config_path)" == "${TEST_TMPDIR}/.config/tmux/tmux.conf" ]]
  rm -f "${TEST_TMPDIR}/.config/tmux/tmux.conf"
  [[ "$(_config_path)" == "${TEST_TMPDIR}/.tmux.conf" ]]
}

@test "applier - helper functions are defined" {
  function_exists apply_sensible
  function_exists _emit
  function_exists _set_default
  function_exists _set_default_terminal
  function_exists _apply_copy_bindings
  function_exists _config_path
}
