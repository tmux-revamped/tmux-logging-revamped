#!/bin/sh
# shellcheck disable=SC2034

[ -n "${LOGGING_REVAMPED_CORE_LOADED:-}" ] && return 0
LOGGING_REVAMPED_CORE_LOADED=1

readonly LOGGING_REVAMPED_VERSION="3.0.0"
