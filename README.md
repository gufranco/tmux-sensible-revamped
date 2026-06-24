<div align="center">

<h1>tmux-sensible-revamped</h1>

**Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering your config.**

[![Tests](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)](CHANGELOG.md)

</div>

**30+** normalized settings · **tmux 1.9 to 3.5** · **Linux, macOS, WSL** · **63** tests · **95%+** coverage

One config that behaves the same regardless of the tmux version, the operating system, the terminal emulator, and what is running inside the pane. Every option is gated to the tmux versions that support it, so the same plugin runs cleanly on every tmux TPM supports, from 1.9 up. Truecolor, the system clipboard, undercurl, and extended keys are enabled per detected capability, and several long-standing terminal bugs are worked around. Your own explicit settings always win.

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><strong>Version-aware</strong><br>Each option is applied only on the tmux versions that support it, so nothing errors from 1.9 to 3.5.</td>
<td><strong>Terminal-aware</strong><br>Truecolor, OSC 52 clipboard, undercurl, and CSI u keys are enabled per detected capability, with per-emulator fixes.</td>
</tr>
<tr>
<td><strong>Clipboard everywhere</strong><br>Copy lands in the system clipboard on Wayland, X11, macOS, and WSL, and over SSH through OSC 52.</td>
<td><strong>Non-destructive</strong><br>Preference options are set only when you have not changed them, so explicit configuration is never overwritten.</td>
</tr>
</table>

## What it normalizes

Options above your tmux version are skipped silently. The minimum is tmux 1.9, the floor TPM supports.

| Area | Settings | Min tmux |
|------|----------|----------|
| Latency and focus | `escape-time 10` (kills the vim ESC delay), `focus-events on` | 1.9 |
| Color | `default-terminal tmux-256color` with a `screen-256color` fallback, truecolor via `terminal-features ,*:RGB` or the legacy `Tc` override | 3.2 for features, any for the override |
| Underlines | undercurl and colored underline overrides (`Smulx`, `Setulc`) | 3.0 |
| Clipboard and capabilities | `set-clipboard on`, `allow-passthrough on`, and the `clipboard`, cursor color, cursor style, focus, and title terminal features | on any, 3.2, 3.3 |
| Extended keys | `extended-keys on` on terminals that support CSI u, the `extkeys` feature, `extended-keys-format csi-u` | 3.2, 3.5 for the format |
| Scrollback and status | `history-limit 50000`, `display-time 4000`, `status-interval 5`, `repeat-time 1000` | any |
| Window and pane | `base-index 1`, `pane-base-index 1`, `renumber-windows on`, `automatic-rename on`, `aggressive-resize on` for normal clients, off under iTerm2 control mode | 1.6 and 1.7 where noted |
| Copy mode | `mode-keys` from `$EDITOR`, system-clipboard yank and mouse-drag bindings for vi and emacs keys | any |

It also carries over every default binding from upstream tmux-sensible, each set only when the key is still free: `prefix + R` reloads the config resolving the path in XDG order, the prefix letter switches to the last window, `C-p` and `C-n` move between windows, and `send-prefix` is wired when the prefix is not `C-b`. The macOS `reattach-to-user-namespace` wrapper is installed only when that legacy helper is present.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

Then press `prefix + I` to install. Place it early so your own settings, sourced later, take precedence.

Manual install:

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

## Behavior notes

- **Your config wins.** Scrollback, display time, status interval, repeat time, base index, and the terminal type are applied only when still at the tmux default, so a value you set yourself is left alone.
- **Nothing noisy is forced.** It does not touch activity monitoring, the title format, or the mouse, so your own choices there are never overridden.
- **Mouse stays off.** Enabling the mouse breaks terminal-native selection for many users, so this plugin does not touch it.
- **Prefix is untouched.** It keeps `C-b`, matching upstream tmux-sensible.
- **Clipboard order.** The copy command is chosen by environment: Wayland `wl-copy`, WSL `clip.exe`, macOS `pbcopy`, X11 `xclip` then `xsel`. With none available it relies on `set-clipboard on` and OSC 52, which also carries the clipboard back over SSH.

## Known bugs it works around

| Symptom | Fix |
|---------|-----|
| vim or neovim lag when leaving insert mode | `escape-time 10` |
| Truecolor not working inside tmux | `default-terminal tmux-256color` plus the `RGB` capability, not a non-256 terminal type |
| Italics rendering as reverse video | `tmux-256color` instead of `screen-256color` |
| Clipboard not propagating over SSH | `set-clipboard on` and the OSC 52 `clipboard` feature |
| iTerm2 native integration breaking on resize | `aggressive-resize` is off only under iTerm2 control mode (a client-attached hook on tmux 3.0+), on everywhere else |
| Apple Terminal.app | left at 256 colors, since it has neither truecolor nor OSC 52 |

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64), macOS (Intel and Apple Silicon), and WSL. Capabilities such as truecolor, OSC 52 clipboard, undercurl, and extended keys also depend on the outer terminal supporting them. iTerm2, Alacritty, Kitty, WezTerm, Ghostty, Konsole, Windows Terminal, and recent xterm support the full set; GNOME Terminal lacks OSC 52; Apple Terminal.app lacks truecolor and OSC 52.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

The decision logic lives in [`src/lib/sensible/sensible.sh`](src/lib/sensible/sensible.sh) as pure, seam-backed helpers, and the applier in [`src/sensible.sh`](src/sensible.sh) runs under a dry-run mode so the full version matrix is validated without a live tmux.

## License

[MIT](LICENSE), copyright Gustavo Franco.
