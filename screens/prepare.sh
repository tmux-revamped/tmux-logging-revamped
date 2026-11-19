#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin" "${demo}/tmux-logging-revamped"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/logging-revamped.tmux" "${demo}/tmux-logging-revamped/"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"
