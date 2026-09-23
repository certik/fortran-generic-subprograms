#!/bin/sh
# Familiar entry point:
#   FC='ccache gfortran' FCFLAGS='-std=f2023 -O0' ./tests/run.sh
#   CC='ccache cc' CFLAGS='-O0' ./tests/run.sh valid/mixed_case_directory
#   ./tests/run.sh valid/factorial.f90
# Metadata-only commands:
#   ./tests/run.sh list --json
#   ./tests/run.sh check

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE
exec python3 "$script_dir/runner.py" "$@"
