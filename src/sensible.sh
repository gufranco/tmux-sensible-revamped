#!/usr/bin/env bash
#
# sensible.sh: apply normalized, version-aware, OS-aware, terminal-aware tmux
# defaults. Every option is gated to the tmux versions TPM supports (1.9 and up),
# so an option that does not exist on the running tmux is simply skipped.
#
# With SENSIBLE_DRY_RUN set, each tmux command is printed instead of run, which
# is how the test suite validates the full decision matrix without a live tmux.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Default word-separators string tmux 2.0+ ships. Setting word-separators is only
# non-destructive when the live value still matches this, so it is stored once
# instead of being repeated inline.
SENSIBLE_DEFAULT_WORD_SEPARATORS='!"#$%&'\''()*+,-./:;<=>?@[\]^`{|}~'

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/sensible/sensible.sh"

# _emit ARGS... -> run `tmux ARGS`, or print it under SENSIBLE_DRY_RUN.
_emit() {
  if [[ -n "${SENSIBLE_DRY_RUN:-}" ]]; then
    echo "$*"
  else
    tmux "$@"
  fi
}

# _get_option OPT -> the current global value of OPT.
_get_option() { tmux show-option -gqv "${1}" 2>/dev/null; }

# _set_default OPT DEFAULT VALUE -> set VALUE only when the user has not changed
# OPT from the tmux default, so explicit user configuration always wins.
_set_default() {
  local opt="${1}" def="${2}" val="${3}" cur
  cur="$(_get_option "${opt}")"
  if [[ -z "${cur}" || "${cur}" == "${def}" ]]; then
    _emit set -g "${opt}" "${val}"
  fi
}

# _set_server_default OPT DEFAULT VALUE -> the server-scope counterpart.
_set_server_default() {
  local opt="${1}" def="${2}" val="${3}" cur
  cur="$(_get_server_option "${opt}")"
  if [[ -z "${cur}" || "${cur}" == "${def}" ]]; then
    _emit set -sg "${opt}" "${val}"
  fi
}

# _set_window_default OPT DEFAULT VALUE -> the window-scope counterpart.
_set_window_default() {
  local opt="${1}" def="${2}" val="${3}" cur
  cur="$(_get_window_option "${opt}")"
  if [[ -z "${cur}" || "${cur}" == "${def}" ]]; then
    _emit setw -g "${opt}" "${val}"
  fi
}

# _set_default_terminal VALUE -> set default-terminal at both session and server
# scope, but only while it is still effectively unconfigured. The bare tmux
# default `screen` and the common `screen-256color` both count as unconfigured so
# the upgrade fires; any other explicit value is left alone.
_set_default_terminal() {
  local val="${1}" cur
  cur="$(_get_option default-terminal)"
  if default_terminal_unset "${cur}"; then
    _emit set -g default-terminal "${val}"
  fi
  cur="$(_get_server_option default-terminal)"
  if default_terminal_unset "${cur}"; then
    _emit set -sg default-terminal "${val}"
  fi
}

# _config_path -> the active tmux config file, XDG aware.
_config_path() {
  if [[ -n "${XDG_CONFIG_HOME:-}" && -f "${XDG_CONFIG_HOME}/tmux/tmux.conf" ]]; then
    echo "${XDG_CONFIG_HOME}/tmux/tmux.conf"
  elif [[ -f "${HOME}/.config/tmux/tmux.conf" ]]; then
    echo "${HOME}/.config/tmux/tmux.conf"
  else
    echo "${HOME}/.tmux.conf"
  fi
}

# _apply_copy_bindings VER CLIP -> wire copy-mode yank and mouse drag to the system
# clipboard. tmux 2.4 unified copy commands under `send-keys -X`; older tmux uses
# the `vi-copy`/`emacs-copy` key tables and lacks the `-and-cancel` variants. With
# no local tool, fall back to a plain copy that still emits OSC 52 when
# set-clipboard is on. The vi selection keys (v, C-v, Enter) are restored too.
_apply_copy_bindings() {
  local ver="${1}" clip="${2}"
  if version_ge "${ver}" 2.4; then
    if [[ -n "${clip}" ]]; then
      _emit bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode M-w send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"
    else
      _emit bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      _emit bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
      _emit bind-key -T copy-mode M-w send-keys -X copy-selection-and-cancel
    fi
    _emit bind-key -T copy-mode-vi v send-keys -X begin-selection
    _emit bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
  else
    if [[ -n "${clip}" ]]; then
      _emit bind-key -t vi-copy y copy-pipe "${clip}"
      _emit bind-key -t emacs-copy M-w copy-pipe "${clip}"
    else
      _emit bind-key -t vi-copy y copy-selection
      _emit bind-key -t emacs-copy M-w copy-selection
    fi
    _emit bind-key -t vi-copy v begin-selection
    _emit bind-key -t vi-copy C-v rectangle-toggle
  fi
}

# apply_sensible -> the full normalization pass.
apply_sensible() {
  local ver os dt mk clip conf prefix prefix_letter iterm=0
  local tc=0 has_direct=0 has_256=0
  ver="$(tmux_version)"
  os="$(current_os)"
  mk="$(editor_mode_keys "${EDITOR:-}${VISUAL:-}")"
  is_iterm "${TERM_PROGRAM:-}" "${LC_TERMINAL:-}" && iterm=1

  # Color capability: truecolor from COLORTERM or terminfo, nested TERMs excluded.
  should_truecolor "${COLORTERM:-}" "${TERM:-}" && tc=1
  _has_terminfo tmux-direct && has_direct=1
  _has_terminfo tmux-256color && has_256=1

  # Terminal type. tmux-direct when truecolor and its terminfo are both present,
  # else tmux-256color, applied only while default-terminal is unconfigured.
  dt="$(choose_default_terminal "${tc}" "${has_direct}" "${has_256}")"
  _set_default_terminal "${dt}"

  if [[ "${tc}" -eq 1 ]]; then
    if version_ge "${ver}" 3.2; then
      _emit set -as terminal-features ",*:RGB"
    else
      _emit set -ga terminal-overrides ",*:Tc"
    fi
  fi
  if version_ge "${ver}" 3.0; then
    _emit set -ga terminal-overrides ',*:Smulx=\E[4::%p1%dm'
    _emit set -ga terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
  fi

  # OSC 52 clipboard and cursor-shape passthrough on tmux below 3.2, where the
  # clipboard and cstyle terminal-features do not exist yet. Emitted only for
  # terminals known to honor the escapes.
  if ! version_ge "${ver}" 3.2; then
    if osc52_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _emit set -ga terminal-overrides ',*:Ms=\E]52;%p1%s;%p2%s\007'
    fi
    if cursor_shape_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _emit set -ga terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'
    fi
  fi

  # Latency and focus.
  _set_server_default escape-time 500 10
  if version_ge "${ver}" 1.9; then
    _set_default focus-events off on
  fi

  # Clipboard and OSC 52. The default value is `external`, not `on`.
  _set_default set-clipboard external on
  if version_ge "${ver}" 3.2; then
    # Safe capability declarations: clipboard, cursor color, cursor style, focus
    # reporting, and title setting. Unlike RGB these never garble a terminal that
    # lacks them, so they apply to every terminal.
    _emit set -as terminal-features ",*:clipboard:ccolour:cstyle:focus:title"
    _emit set -as terminal-features ",rxvt*:ignorefkeys"
  fi
  # allow-passthrough keeps graphics alive in panes. `all` (3.4+) also updates
  # inactive panes; 3.3 only understands `on`. Default-aware so a user value wins.
  if version_ge "${ver}" 3.4; then
    _set_default allow-passthrough off all
  elif version_ge "${ver}" 3.3; then
    _set_default allow-passthrough off on
  fi
  # Sixel graphics and OSC 8 hyperlinks are declarable from 3.4.
  if version_ge "${ver}" 3.4; then
    if sixel_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _emit set -as terminal-features ",*:sixel"
    fi
    if hyperlink_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _emit set -as terminal-features ",*:hyperlinks"
    fi
  fi

  # Extended keys (CSI u), only on terminals that support the protocol.
  if version_ge "${ver}" 3.2 && extended_keys_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
    _emit set -s extended-keys on
    _emit set -as terminal-features "xterm*:extkeys"
    if version_ge "${ver}" 3.5; then
      _emit set -s extended-keys-format csi-u
    fi
  fi

  # Scrollback, messages, activity.
  _set_default history-limit 2000 50000
  _set_default display-time 750 4000
  _set_default status-interval 15 5
  _set_default repeat-time 500 1000
  _set_default display-panes-time 1000 2000
  _set_default status-keys emacs emacs
  _set_default set-titles off on

  # Word selection: drop the punctuation separators so a double-click grabs a whole
  # path or URL. Default-aware against the tmux 2.0+ default string.
  _set_window_default word-separators "${SENSIBLE_DEFAULT_WORD_SEPARATORS}" " "

  # Window and pane hygiene.
  _set_default base-index 0 1
  if version_ge "${ver}" 1.6; then
    _emit setw -g pane-base-index 1
  fi
  if version_ge "${ver}" 1.7; then
    _emit set -g renumber-windows on
  fi
  _emit setw -g automatic-rename on
  # aggressive-resize on for normal clients, off under iTerm2's native tmux
  # integration (control mode), where it makes iTerm2 refuse to attach. On tmux
  # 3.0+ a client-attached hook decides per client, so plain tmux gets it in every
  # terminal and control mode stays safe without ever turning it on at load time.
  # Older tmux has no indexed hooks, so it keeps the conservative skip-all-iTerm2.
  if version_ge "${ver}" 3.0; then
    _emit set-hook -g 'client-attached[1000]' "if-shell -F '#{client_control_mode}' 'setw -g aggressive-resize off' 'setw -g aggressive-resize on'"
  elif [[ "${iterm}" -eq 0 ]]; then
    _emit setw -g aggressive-resize on
  fi

  # Copy mode and clipboard bindings. mode-keys follows the editor but never
  # overrides an explicit user choice.
  _set_window_default mode-keys emacs "${mk}"
  clip="$(resolve_clipboard)"
  _apply_copy_bindings "${ver}" "${clip}"

  # macOS pasteboard wrapper, only when the legacy helper is installed.
  if [[ "${os}" == "darwin" ]] && _have reattach-to-user-namespace; then
    # shellcheck disable=SC2016
    _emit set -g default-command 'reattach-to-user-namespace -l $SHELL'
  fi

  # Window navigation and prefix bindings, only when not already bound.
  prefix="$(_prefix)"
  prefix_letter="${prefix#*-}"
  if [[ -n "${prefix}" && "${prefix}" != "C-b" ]]; then
    _emit unbind-key C-b
    if _key_unbound "${prefix}"; then
      _emit bind-key "${prefix}" send-prefix
    fi
  fi
  if [[ -n "${prefix_letter}" ]] && _key_unbound "${prefix_letter}"; then
    _emit bind-key "${prefix_letter}" last-window
  fi
  if _key_unbound C-p; then
    _emit bind-key C-p previous-window
  fi
  if _key_unbound C-n; then
    _emit bind-key C-n next-window
  fi

  # Reload binding, only when R is free.
  if _key_unbound R; then
    conf="$(_config_path)"
    _emit bind-key R source-file "${conf}" ";" display-message "tmux-sensible-revamped: reloaded"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  apply_sensible
fi
