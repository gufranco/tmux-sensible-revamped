#!/usr/bin/env bash
#
# sensible-revamped.tmux: TPM entry point.
#
# Applies the normalized defaults. Every option is version-gated, so this runs
# cleanly on every tmux version TPM supports (1.9 and up).

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${CURRENT_DIR}/src/sensible.sh"
