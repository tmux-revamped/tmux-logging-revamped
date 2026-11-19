#!/bin/sh

logging_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${logging_revamped_dir}/bin/logging-revamped" apply
