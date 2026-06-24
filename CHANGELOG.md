# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
