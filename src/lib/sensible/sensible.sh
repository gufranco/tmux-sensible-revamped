#!/usr/bin/env bash
#
# sensible.sh: pure decision helpers for tmux-sensible-revamped.
#
# These functions decide WHAT to normalize. They never call `tmux set`; the
# applier does that. Host probes (the running tmux version, the OS, command
# availability, terminfo) sit behind seams the tests override, so the decisions
# are validated without a live tmux or a specific machine.

[[ -n "${_SENSIBLE_REVAMPED_LOADED:-}" ]] && return 0
_SENSIBLE_REVAMPED_LOADED=1

# parse_tmux_version TEXT -> the major.minor number from `tmux -V` output.
# Handles "tmux 3.4", "tmux 3.4a", "tmux next-3.5", "tmux 3.5-rc".
parse_tmux_version() {
  printf '%s\n' "${1}" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

# version_ge HAVE WANT -> 0 when HAVE is greater than or equal to WANT.
version_ge() {
  [[ -n "${1}" && -n "${2}" ]] || return 1
  [ "$(printf '%s\n%s\n' "${2}" "${1}" | sort -V | head -n1)" = "${2}" ]
}

# truecolor_supported COLORTERM -> 0 when the value advertises 24-bit color.
truecolor_supported() {
  case "${1}" in
    *truecolor*|*24bit*) return 0 ;;
    *) return 1 ;;
  esac
}

# extended_keys_terminal TERM TERM_PROGRAM -> 0 for terminals known to handle the
# CSI u extended-keys protocol, so it is never forced on a terminal that garbles
# the resulting sequences.
extended_keys_terminal() {
  case "${2}" in
    iTerm.app|WezTerm|ghostty|mintty) return 0 ;;
  esac
  case "${1}" in
    xterm*|*kitty*|foot*) return 0 ;;
    *) return 1 ;;
  esac
}

# os_kind UNAME PROC_VERSION -> darwin|wsl|linux|other.
os_kind() {
  case "${1}" in
    Darwin) echo "darwin"; return 0 ;;
  esac
  case "${2}" in
    *[Mm]icrosoft*|*WSL*) echo "wsl"; return 0 ;;
  esac
  case "${1}" in
    Linux) echo "linux" ;;
    *) echo "other" ;;
  esac
}

# is_iterm TERM_PROGRAM LC_TERMINAL -> 0 when running under iTerm2, matching
# either signal the way upstream tmux-sensible does.
is_iterm() {
  case "${1}" in iTerm*) return 0 ;; esac
  case "${2}" in iTerm*) return 0 ;; esac
  return 1
}

# editor_mode_keys EDITOR_VALUE -> vi when the editor is a vi family, else emacs.
editor_mode_keys() {
  case "${1}" in
    *vi*) echo "vi" ;;
    *) echo "emacs" ;;
  esac
}

# Host-probe seams. Tests override these.
_tmux_version_string() { tmux -V 2>/dev/null; }
_have() { command -v "${1}" >/dev/null 2>&1; }
_uname() { uname -s 2>/dev/null; }
_proc_version() { cat /proc/version 2>/dev/null; }
_has_terminfo() { infocmp "${1}" >/dev/null 2>&1; }
_prefix() { tmux show-option -gv prefix 2>/dev/null; }
_get_server_option() { tmux show-option -sqv "${1}" 2>/dev/null; }
_get_window_option() { tmux show-option -wgqv "${1}" 2>/dev/null; }

# _key_unbound KEY -> 0 when KEY has no prefix-table binding, so a user binding is
# never clobbered. Mirrors upstream tmux-sensible's list-keys match.
_key_unbound() {
  local key="${1//\\/\\\\}"
  ! tmux list-keys 2>/dev/null | grep -q "bind-key[[:space:]]\+\(-r[[:space:]]\+\)\?\(-T prefix[[:space:]]\+\)\?${key}[[:space:]]"
}

# clipboard_command WAYLAND DISPLAY OS -> the system copy command, or empty when
# none is available and OSC 52 must carry the clipboard. Priority: Wayland, WSL,
# macOS, X11 (xclip then xsel).
clipboard_command() {
  local wayland="${1}" display="${2}" os="${3}"
  if [[ -n "${wayland}" ]] && _have wl-copy; then
    echo "wl-copy"; return 0
  fi
  if [[ "${os}" == "wsl" ]] && _have clip.exe; then
    echo "clip.exe"; return 0
  fi
  if [[ "${os}" == "darwin" ]] && _have pbcopy; then
    echo "pbcopy"; return 0
  fi
  if [[ -n "${display}" ]] && _have xclip; then
    echo "xclip -selection clipboard"; return 0
  fi
  if [[ -n "${display}" ]] && _have xsel; then
    echo "xsel -ib"; return 0
  fi
  echo ""
}

# Composed readers used by the applier.
tmux_version() { parse_tmux_version "$(_tmux_version_string)"; }
current_os() { os_kind "$(_uname)" "$(_proc_version)"; }
default_terminal() { if _has_terminfo tmux-256color; then echo "tmux-256color"; else echo "screen-256color"; fi; }
resolve_clipboard() { clipboard_command "${WAYLAND_DISPLAY:-}" "${DISPLAY:-}" "$(current_os)"; }

export -f parse_tmux_version
export -f version_ge
export -f truecolor_supported
export -f extended_keys_terminal
export -f os_kind
export -f is_iterm
export -f editor_mode_keys
export -f _tmux_version_string
export -f _have
export -f _uname
export -f _proc_version
export -f _has_terminfo
export -f _prefix
export -f _get_server_option
export -f _get_window_option
export -f _key_unbound
export -f clipboard_command
export -f tmux_version
export -f current_os
export -f default_terminal
export -f resolve_clipboard
