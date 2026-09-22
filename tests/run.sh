#!/bin/sh
# Compile and run the Fortran 2028 auto-generic conformance tests.
#
#   FC=lfortran FCFLAGS=... ./tests/run.sh
#   ./tests/run.sh valid/factorial.f90 invalid/mod_requires_same_kind.f90
#
# valid/*.f90 must compile, run, and exit 0.
# runtime/*.f90 must compile and then error-terminate.
# invalid/*.f90 must be rejected at compile time.
# A path passed on the command line is classified by the directory it lives in.

set -u

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
fc=${FC:-lfortran}
flags=${FCFLAGS:-}
logdir=${TMPDIR:-/tmp}/auto-generic-conformance
rm -rf "$logdir"
mkdir -p "$logdir"

pass=0
fail=0
failed_names=""

classify() {
  case $(basename "$(dirname "$1")") in
    valid) printf valid ;;
    runtime) printf runtime ;;
    invalid) printf invalid ;;
    *) printf unknown ;;
  esac
}

record() {
  kind=$1
  src=$2
  status=$3
  name=$(basename "$src")
  if [ "$status" -eq 0 ]; then
    pass=$((pass + 1))
    printf 'PASS  %s  %s\n' "$kind" "$name"
  else
    fail=$((fail + 1))
    failed_names="$failed_names $kind/$name"
    printf 'FAIL  %s  %s\n' "$kind" "$name"
  fi
}

run_one() {
  src=$1
  kind=$(classify "$src")
  base=$(basename "$src" .f90)
  abs=$(CDPATH= cd -- "$(dirname "$src")" && pwd)/$(basename "$src")
  out="$logdir/$base.out"
  log="$logdir/$base.log"

  case $kind in
    valid)
      if (cd "$logdir" && "$fc" $flags "$abs" -o "$out") >"$log" 2>&1 \
          && "$out" >>"$log" 2>&1; then
        record valid "$src" 0
      else
        record valid "$src" 1
      fi
      ;;
    runtime)
      if (cd "$logdir" && "$fc" $flags "$abs" -o "$out") >"$log" 2>&1; then
        if "$out" >>"$log" 2>&1; then
          record runtime "$src" 1
        else
          record runtime "$src" 0
        fi
      else
        record runtime "$src" 1
      fi
      ;;
    invalid)
      if (cd "$logdir" && "$fc" $flags -c "$abs") >"$log" 2>&1; then
        record invalid "$src" 1
      else
        record invalid "$src" 0
      fi
      ;;
    *)
      printf 'SKIP  unknown category for %s\n' "$src"
      fail=$((fail + 1))
      ;;
  esac
}

if [ "$#" -eq 0 ]; then
  set -- "$root"/tests/valid/*.f90 "$root"/tests/runtime/*.f90 "$root"/tests/invalid/*.f90
fi

printf 'FC=%s\n' "$fc"
for src in "$@"; do
  run_one "$src"
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
printf 'logs: %s\n' "$logdir"
if [ "$fail" -ne 0 ]; then
  printf 'failed:%s\n' "$failed_names"
  exit 1
fi
exit 0
