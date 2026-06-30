# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-30

### Added

- OSC 52 clipboard reach on tmux below 3.2 through an `Ms` terminal override for
  terminals known to honor it, so copy works over SSH on older tmux.
- Cursor-shape passthrough (`Ss`/`Se`) on tmux below 3.2, so vi and neovim switch
  between block and bar cursors.
- `tmux-direct` as the default-terminal when truecolor and its terminfo are both
  present, for native direct color.
- Truecolor fallback from terminfo when `COLORTERM` is unset, covering mosh and
  some emulators.
- `allow-passthrough all` on tmux 3.4+, keeping graphics updating in inactive
  panes, with `on` on 3.3.
- sixel and OSC 8 hyperlink terminal features on tmux 3.4+ for capable terminals.
- Termux clipboard support via `termux-clipboard-set`.
- vi copy-mode selection keys (`v`, `C-v`, `Enter`) and path-friendly
  `word-separators`.
- `set-titles on` and a longer `display-panes-time`, both default-aware.

### Changed

- Force-set options (`focus-events`, `set-clipboard`, `allow-passthrough`,
  `status-keys`) are now applied through the default-aware setter, so an explicit
  user value is preserved.
- Copy bindings are version-gated: `copy-pipe-and-cancel` is emitted only on tmux
  2.4+, and the `vi-copy`/`emacs-copy` key tables are used below it, so copy works
  down to the 1.9 floor.
- `screen-256color` is treated as an unconfigured default-terminal so the
  `tmux-256color` upgrade fires.
- Nested screen and tmux TERM values are no longer tagged truecolor, avoiding
  garbled color inside a nested multiplexer.
- Broadened the CSI u extended-keys allowlist to Alacritty, Contour, Rio, st, and
  Konsole.
- WSL clipboard prefers an X11 tool over `clip.exe` when a display is present, so
  WSLg sessions keep UTF-8-safe copy.

## [1.0.1] - 2026-06-23

### Changed

- Reviewed the upstream `tmux-plugins/tmux-sensible` issues and pull requests.
  The control-mode-aware aggressive-resize (#78), the macOS `default-command`
  with `$SHELL` through `reattach-to-user-namespace` (#74, PR #75), and the
  XDG_CONFIG_HOME-aware config path (PR #68) are all already in place. No code
  change needed.

## [1.0.0] - 2026-06-20

### Added

- Version-aware normalization for tmux 1.9 and up. Every option is gated to the
  versions that support it, so nothing errors on the range TPM supports.
- Terminal capability setup: truecolor via terminal-features or the legacy Tc
  override, OSC 52 clipboard, undercurl, and CSI u extended keys, each per
  detected tmux version.
- Cross-platform clipboard: copy resolves to wl-copy, clip.exe, pbcopy, xclip, or
  xsel by environment, with OSC 52 as the universal fallback that also works over
  SSH.
- Worked-around bugs: the vim ESC delay, truecolor and italics misconfiguration,
  clipboard over SSH, and iTerm2 aggressive-resize breakage.
- Non-destructive defaults: preference options are applied only when still at the
  tmux default, so explicit user configuration is preserved.
- Full upstream tmux-sensible parity: every option plus all default key bindings
  (send-prefix, last-window, previous and next window, reload), each applied only
  when the key or option is still unset.
