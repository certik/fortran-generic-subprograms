#!/bin/sh
# Compile and run the Fortran 2028 auto-generic conformance tests.
#
#   FC=lfortran FCFLAGS=... ./tests/run.sh
#   ./tests/run.sh valid/factorial.f90 invalid_compile_time/mod_requires_same_kind.f90
#
# valid/*.f90
#     Compile, run, and exit 0. A failed check is `error stop`.
# valid/<name>/
#     Several sources, compiled separately in lexical order, then linked and run.
# invalid_runtime/*.f90
#     Compile, then terminate with a nonzero status that is not a signal death.
#     These programs are conforming; the nonzero status is the program's own
#     error stop. A crash (status 128 or above) is a failure of the compiler.
# invalid_compile_time/*.f90 and invalid_compile_time/<name>/
#     Rejected while compiling or linking.
#
# A path passed on the command line is classified by the category directory
# that contains it. The runner records that a translation failed; it does not
# parse the diagnostic text.

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

has_program() {
  grep -E '^[[:space:]]*program([[:space:]]|$)' "$1" >/dev/null 2>&1
}

classify() {
  here=$1
  while [ "$here" != "/" ]; do
    case $(basename "$here") in
      valid|invalid_compile_time|invalid_runtime)
        printf '%s' "$(basename "$here")"
        return
        ;;
    esac
    here=$(dirname "$here")
  done
  printf unknown
}

record() {
  kind=$1
  src=$2
  status=$3
  name=${src#"$root"/tests/}
  if [ "$status" -eq 0 ]; then
    pass=$((pass + 1))
    printf 'PASS  %s  %s\n' "$kind" "$name"
  else
    fail=$((fail + 1))
    failed_names="$failed_names $name"
    printf 'FAIL  %s  %s\n' "$kind" "$name"
  fi
}

compile_one() {
  src=$1
  obj=$2
  log=$3
  work=$4
  # Compile a copy in the work directory so module files stay out of the tree.
  cp "$src" "$work/$(basename "$src")"
  (cd "$work" && "$fc" $flags -c "$(basename "$src")" -o "$(basename "$obj")") >>"$log" 2>&1
}

link_objs() {
  work=$1
  out=$2
  log=$3
  set -- "$work"/*.o
  (cd "$work" && "$fc" $flags "$@" -o "$out") >>"$log" 2>&1
}

# Compile every .f90 directly in dir, in lexical order, then link.
# Returns 0 when an executable was produced.
compile_dir() {
  dir=$1
  work=$2
  log=$3
  mkdir -p "$work"
  : >"$log"
  # Lexical order, not the shell's glob order: the module file is a_*.f90.
  set -- $(find "$dir" -mindepth 1 -maxdepth 1 -name '*.f90' | sort)
  for src in "$@"; do
    base=$(basename "$src" .f90)
    if ! compile_one "$src" "$work/$base.o" "$log" "$work"; then
      return 1
    fi
  done
  link_objs "$work" "$work/out" "$log"
}

run_status_ok() {
  # 0 means the program did not fail. 128 and above is a signal death
  # (128+signal in this shell), which is not the error stop we asked for.
  rc=$1
  [ "$rc" -ne 0 ] && [ "$rc" -lt 128 ]
}

run_one() {
  src=$1
  kind=$(classify "$src")
  base=$(basename "$src" .f90)
  abs=$(CDPATH= cd -- "$(dirname "$src")" && pwd)/$(basename "$src")
  work="$logdir/$kind/$base"
  out="$work/out"
  log="$logdir/$kind/$base.log"
  mkdir -p "$work"

  case $kind in
    valid)
      if compile_one "$abs" "$work/$base.o" "$log" "$work" \
          && link_objs "$work" "$out" "$log" \
          && "$out" >>"$log" 2>&1; then
        record valid "$src" 0
      else
        record valid "$src" 1
      fi
      ;;
    invalid_runtime)
      if compile_one "$abs" "$work/$base.o" "$log" "$work" \
          && link_objs "$work" "$out" "$log"; then
        "$out" >>"$log" 2>&1
        rc=$?
        if run_status_ok "$rc"; then
          record invalid_runtime "$src" 0
        else
          record invalid_runtime "$src" 1
        fi
      else
        record invalid_runtime "$src" 1
      fi
      ;;
    invalid_compile_time)
      if ! compile_one "$abs" "$work/$base.o" "$log" "$work"; then
        record invalid_compile_time "$src" 0
      elif has_program "$abs" && ! link_objs "$work" "$out" "$log"; then
        # A complete program can also be rejected at link time, for example
        # an undefined separate module procedure.
        record invalid_compile_time "$src" 0
      else
        record invalid_compile_time "$src" 1
      fi
      ;;
    *)
      printf 'SKIP  unknown category for %s\n' "$src"
      fail=$((fail + 1))
      ;;
  esac
}

run_group() {
  dir=$1
  dir=${dir%/}
  kind=$(classify "$dir")
  base=$(basename "$dir")
  work="$logdir/$kind/$base"
  log="$logdir/$kind/$base.log"
  abs=$(CDPATH= cd -- "$dir" && pwd)

  case $kind in
    valid)
      if compile_dir "$abs" "$work" "$log" && "$work/out" >>"$log" 2>&1; then
        record valid "$dir" 0
      else
        record valid "$dir" 1
      fi
      ;;
    invalid_runtime)
      if compile_dir "$abs" "$work" "$log"; then
        "$work/out" >>"$log" 2>&1
        rc=$?
        if run_status_ok "$rc"; then
          record invalid_runtime "$dir" 0
        else
          record invalid_runtime "$dir" 1
        fi
      else
        record invalid_runtime "$dir" 1
      fi
      ;;
    invalid_compile_time)
      if compile_dir "$abs" "$work" "$log"; then
        record invalid_compile_time "$dir" 1
      else
        record invalid_compile_time "$dir" 0
      fi
      ;;
    *)
      printf 'SKIP  unknown category for %s\n' "$dir"
      fail=$((fail + 1))
      ;;
  esac
}

collect_default() {
  for cat in valid invalid_runtime invalid_compile_time; do
    find "$root/tests/$cat" -mindepth 1 -maxdepth 1 -name '*.f90' | sort
    find "$root/tests/$cat" -mindepth 1 -maxdepth 1 -type d | sort
  done
}

printf 'FC=%s\n' "$fc"
if [ "$#" -eq 0 ]; then
  set --
  # shellcheck disable=SC2046
  set -- $(collect_default)
fi

for src in "$@"; do
  if [ -d "$src" ]; then
    run_group "$src"
  else
    run_one "$src"
  fi
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
printf 'logs: %s\n' "$logdir"
if [ "$fail" -ne 0 ]; then
  printf 'failed:%s\n' "$failed_names"
  exit 1
fi
exit 0
