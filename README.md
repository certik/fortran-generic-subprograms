# Auto-generic subprograms: specification and conformance tests

This repository tracks generic subprograms in the Fortran 2028 working draft
**J3/26-007r1** (3 March 2026). The detailed language guide is
[doc/auto-generic-subprograms.md](doc/auto-generic-subprograms.md); the
requirement-to-fixture index is
[doc/conformance-coverage.md](doc/conformance-coverage.md).

The draft, not the older edit paper J3/25-156r1, is authoritative. Some draft
sentences conflict. This repository separates settled rules from those
interpretations instead of treating either side of an unresolved question as a
conformance failure.

## Test classifications

| Classification | Meaning |
| --- | --- |
| Settled syntax or constraint | Clause 4.2 requires a processor to be capable of detecting and reporting it. Translation need not necessarily terminate with a nonzero status. |
| Unnumbered requirement | The source is nonconforming, but 4.2 does not necessarily require a diagnostic. These checks belong to the optional enhanced-diagnostics profile. |
| Draft interpretation | The wording is unresolved or internally inconsistent. These fixtures are skipped by default; an explicitly selected reading is non-gating unless runner policy also requests `--gate-drafts`, which is not a standard-conformance claim. |

This distinction is recorded in fixture metadata. In particular, “diagnosed”
and “rejected” are not synonyms: the default conformance profile verifies a
matching diagnostic for a required-diagnostic case, while a stricter profile
may additionally require unsuccessful translation and may enable enhanced
diagnostics.

## Layout

| Path | Purpose |
| --- | --- |
| `doc/auto-generic-subprograms.md` | Clause-backed language and implementation guide |
| `doc/conformance-coverage.md` | Requirement-to-fixture coverage matrix and known gaps |
| `tests/valid/` | Runtime-positive fixtures, including capability-dependent and separately compiled multi-file cases; every case has a main program and a completion marker |
| `tests/invalid_compile_time/` | Settled negative cases and enhanced-diagnostic cases, classified by metadata |
| `tests/invalid_runtime/` | Conforming programs expected to initiate error termination |
| `tests/draft_interpretations/` | Explicitly quarantined draft readings |
| `tests/run.sh` | Stable runner entry point |

## Reconciled suite inventory

The integrated inventory on 22 September 2026 is:

| Category | Cases |
| --- | ---: |
| Positive cases (`valid` category) | 104 |
| Compile-time diagnostic cases | 251 |
| Expected runtime-termination cases | 3 |
| **Total** | **358** |

These are static fixtures; processor-generated cases and prerequisite records
are additional and are reported separately.

The cases contain 383 Fortran source files and one companion C source.
Twenty-four cases carry `TEST-DRAFT`. The positives
`valid/language_array_domains_expanded.f90` and
`valid/audit_language_identity_ordinary_control.f90` are ordinary
manual-specialization controls rather than generic-subprogram execution.
`./tests/run.sh check` validates metadata, not the Fortran semantics of a
fixture or the implementation of the language feature.

The runner has a Python 3.9-compatible, standard-library-only backend. The
ordinary entry remains:

```sh
FC=lfortran FCFLAGS='...' ./tests/run.sh
```

Common inspection and harness commands are:

```sh
./tests/run.sh --help
./tests/run.sh check
./tests/run.sh check invalid_compile_time/
./tests/run.sh list
./tests/run.sh list --json valid/
./tests/run.sh self-test
```

`check` validates fixture metadata without invoking a compiler. `list` reports
the discovered cases; selectors are relative to `tests/`. `self-test` exercises
the runner using compiler simulators and available native ordinary-Fortran
controls; it is not a generic-subprogram conformance run.

The default execution profile is conformance mode. Strict mode additionally
requires unsuccessful rejection and enables enhanced-diagnostic cases:

```sh
FC=lfortran ./tests/run.sh --mode conformance valid/factorial.f90
FC=lfortran ./tests/run.sh --strict invalid_compile_time/
```

Draft readings are skipped by default. `--draft` selects one or more readings,
including their enhanced-diagnostic observations without requiring `--strict`.
Selected results remain non-gating unless `--gate-drafts` is also requested:

```sh
./tests/run.sh --draft empty-expansion \
  draft_interpretations/negative/empty_rank_range.f90
./tests/run.sh --draft generic-bind-c --gate-drafts \
  draft_interpretations/negative/bind_c_one_specific.f90
```

`--draft` may be repeated, take a comma-separated list, or use `all`.
Making a selected draft result gating is a runner profile policy, never a claim
that the selected interpretation is settled standard conformance.
`character-generic-parse` and `character-ordinary-parse` are mutually
exclusive readings: both may be selected for non-gating observation, but the
runner rejects `--gate-drafts` when both are selected together.
The same rule applies to `literal-rank-limit` and `extended-rank-limit`:
the former observes the written C826 bound, while the latter exercises
processor-advertised extended ranks. Neither profile also imposes the opposite
reading's outcome.

Processor inventory and generated coverage can be inspected or materialized:

```sh
FC=lfortran ./tests/run.sh inventory --json
FC=lfortran ./tests/run.sh generate --output build/generated-cases --force
```

Normal `run` execution inventories the processor and runs generated kind/rank
coverage unless `--no-generated` is specified. Multi-image execution and
timeouts are configured directly:

```sh
FC=gfortran ./tests/run.sh \
  --launcher 'cafrun -n {images} {exe}' \
  --compile-timeout 120 --run-timeout 60 \
  valid/integration_coarray_multi_image.f90
```

The default compile/link timeout is 60 seconds per command and the default
runtime timeout is 20 seconds.

The portable generated rank case always remains gating. Selecting
`extended-rank-limit` adds a separate
`@generated/processor-rank-extended` observation rather than weakening ranks
0 through 15. It explicitly skips when no rank above 15 is advertised.
Generation manifest version 2 records that case's selection, availability,
source, skip reason, and coverage details; `--force` removes a stale extended
source when regenerating without it.

The mixed-language binding-label case uses a companion C helper:

```sh
FC=vendor-fc CC=cc CFLAGS='-O2' ./tests/run.sh \
  --draft generic-bind-c valid/audit_integration_bind_c_abi/
```

Directory `.c` sources are compiled with `--cc`/`--cflags` (or `CC`/`CFLAGS`),
and the objects are linked with the Fortran compiler. The default C command is
`cc`. A missing or malformed C command is an infrastructure error for a
selected mixed-language case, not a compiler-language failure or a covered
skip. Ordinary Fortran-only cases do not resolve or require a C compiler.

Vendor diagnostic wording and source locations for compile-time negative cases
can be adapted without changing the fixture's phase or required/enhanced
classification:

```json
{
  "schema_version": 1,
  "cases": {
    "invalid_compile_time/optional_dummy.f90": {
      "message_regexes": ["optional.*dummy"],
      "location": "marked"
    }
  },
  "rules": {
    "C875": {
      "message_regexes": ["rank.*(maximum|limit)"],
      "location": "source"
    }
  }
}
```

```sh
FC=vendor-fc ./tests/run.sh \
  --diagnostic-expectations vendor-diagnostics.json \
  invalid_compile_time/
```

`location` is `marked` for a `TEST-ERROR-HERE` target, `source` for any source
in the case, or `case-context` when the vendor provides no usable source
location. Case mappings take precedence over rule mappings. Active overrides
are disclosed in human output and JSON results. Fortran does not prescribe
diagnostic wording or source coordinates; these overrides are harness matching
policy, not additional language requirements.

## Runner model

- Each case is built in an isolated work directory with a timeout. Directory
  fixtures are compiled as separate sources in lexical order and then linked.
- Every positive case declares `TEST-PASS: <id>` and prints the corresponding
  exact line after all its assertions, before the main program's `CONTAINS`
  or end. The runner requires status zero, exactly `TEST-IMAGES` matching
  completion lines, and no other `TEST-PASS:` lines. Status zero alone is not
  evidence of success: `ERROR STOP 0` without completion must fail.
- A negative case passes only when the intended phase and diagnostic are
  verified. An unrelated parse error, missing-main link error, echoed source
  line, unknown diagnostic format, or absent output is not evidence for the
  expected rule. A compile-phase diagnostic can satisfy conformance mode even
  with status zero and no object; an object is required only when a later
  compile, link, or execution step needs it.
- Processor capabilities and compiler feature support are different. Optional
  kinds, character sets, coarray launchers, image counts, and extended ranks
  can cause an explicit capability skip; absence of the generic-subprogram
  language feature is a failure, not a successful negative test.
- The runner probes the processor’s kind inventories and generates calls for
  every reported kind. Real-kind coverage includes both real and corresponding
  complex specifics. Payload checks include safe integer boundaries and signs,
  precision-sensitive real/complex values, both logical values, and rank-two
  copies. It also checks per-specific saved state independently by kind, type,
  rank, and the joint type/kind/rank product. A supported kind value may be zero;
  its numeric magnitude is not a width or a safe arithmetic tag.
- Character payload generation distinguishes known system/default, ASCII, and
  ISO 10646 repertoires from opaque additional kinds. The latter use portable
  ordinal-zero fallback rather than inventing a nonzero character code.
  Generated details disclose nonzero-tested and fallback kinds and never claim
  full repertoire or storage-width coverage.
- Generated rank coverage invokes every generic rank specific from zero through
  the selected portable or extended bound repeatedly for per-specific state. It
  does not treat successful construction of one ordinary high-rank array as
  coverage of all intervening generic specifics. Multidimensional payloads
  activate the outermost axis and include dimension-one stride-two actuals.
  Shapes, tested layouts, and memory strides are disclosed with bounded
  allocation sizes; the manifest does not claim all stride-axis combinations.
  An invalid advertised rank minimum fails generation rather than silently
  reducing the tested domain.
- Multi-image cases require a configured launcher. A missing launcher is
  reported as a skip, never as covered execution.
- Runtime error-termination cases print a `TEST-STOP:` marker, execute
  `FLUSH(output_unit)`, and then execute the intended `ERROR STOP`. The runner
  verifies the marker and calibrates the same literal stop-code form and
  literal `QUIET=` value with the same compiler, flags, and launcher; it does
  not assume one fixed message or status. The standard makes the externally
  observed status processor dependent, so there is no portable “1 through
  127” requirement. A reached, calibrated termination can have status 0, 126,
  or 127; reachability and unexpected-return evidence distinguish it from a
  launch failure. Positive tests' status-zero convention is a runner execution
  protocol, not a claim that Fortran specifies operating-system exit statuses.
- `TEST-STOP-IMAGE: N` makes an error-termination case and its calibration stop
  only image N after an initial synchronization; absent metadata retains
  all-image calibration. It is valid only for runtime-negative cases, with
  `1 <= N <= TEST-IMAGES`, and requires exactly one reachability marker.
  Waiting images use `SYNC ALL(STAT=...)` so a normal-STOP mutation cannot hide
  behind a secondary synchronization error. A zero/stopped/failed return is
  reported as an unexpected return. Other processor-dependent synchronization
  errors print a flushed `TEST-INCONCLUSIVE:` line and are reported as errors,
  never as passing error-termination evidence.

Common metadata includes:

```fortran
! TEST-RULE: C802 15.6.2.4
! TEST-REQUIRES: int32 real64 ascii integer_kinds>=2
! TEST-DRAFT: character-generic-parse
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: nonoptional.*dummy
! TEST-ERROR-PHASE: compile
! TEST-ERROR-HERE
! TEST-PASS: factorial
! TEST-STOP: factorial-negative
! TEST-IMAGES: 2
! TEST-STOP-IMAGE: 1
```

These lines illustrate separate case categories: `TEST-PASS` belongs to a
positive case, diagnostic metadata to a compile-time negative, and `TEST-STOP`
to expected error termination.

`TEST-REQUIRES` describes processor capabilities, not permission to skip a
mandatory language feature. `TEST-DRAFT` is non-gating by default; an explicit
`--gate-drafts` run can make selected cases profile-gating without turning the
chosen reading into a standard-conformance requirement.

## Important readings

- Genericity is classified **property by property**. A dummy can have a
  dependent rank and an independently generic kind, or a dependent type and an
  independently generic rank. Only the dependent property ceases to add a
  factor.
- Duplicate kind values, type/kind combinations, and ranks are removed
  semantically when each domain is evaluated. Independent sets form a
  Cartesian product; a generic range or kind array depending on an earlier
  specialization is evaluated and deduplicated for that choice.
- `INT32`, `INT64`, `REAL32`, `REAL64`, and ASCII are optional processor
  capabilities. Negative values denote unavailable named kinds; zero is a
  valid kind value. A runtime `IF` cannot protect a declaration that names an
  unsupported kind.
- Unselected `SELECT GENERIC` blocks are removed before each residual specific
  is checked. An ordinary runtime `IF` has no such exemption.
- Existing name-use constraints still apply: C725 excludes an assumed-type
  `TYPE(*)` name from `SELECT GENERIC RANK`, and C845 permits an assumed-rank
  name in runtime `SELECT RANK`/`SELECT TYPE` but not direct
  `SELECT GENERIC TYPE`.
- C877 permits a `RANK` clause on a named constant, dummy, allocatable, or
  pointer. Thus allocatable and pointer results can follow a generic rank;
  plain local and plain result declarations cannot.
- A generic separate-module interface body contributes all of its specifics to
  an enclosing generic interface. That rule is distinct from the prohibition
  on naming a generic in a `PROCEDURE` statement under another named generic.
- Semantic expansion does not prescribe separate machine-code bodies or
  runtime dispatch. Shared code is conforming if the observable interfaces,
  per-specific saved state, local type scopes, and internal-procedure/host
  identities are preserved. Length, shape, bounds, and dynamic type do not
  add state factors when the generic choices are unchanged.
- Extending a generic does not erase an existing named specific sharing its
  identifier. Specific-procedure contexts can still denote that existing
  procedure; they cannot expose the newly generated anonymous alternatives.

The unresolved readings—including generic declarations in interface bodies,
assumed-length guards, empty expansions, `GENERIC` plus `BIND(C)`, ranks above
15, the mutually exclusive parses of `CHARACTER(LEN=*)`, mixed
character-length deduplication, template integration, and
`PROCEDURE_NAME`—are documented in the guide and coverage matrix.

## Interpreting results

A successful run establishes only the behavior exercised under the reported
compiler and processor profile. It does not prove complete language
conformance, execution of skipped capabilities, correctness of a quarantined
draft interpretation, or absence of untested corner cases.

Run reports use JSON schema version 2. `summary.profile_success` means at
least one case executed and no gating case failed. `summary.coverage_complete`
means every selected coverage case executed; it does not mean every case
passed. `skipped_cases`, `unexecuted_cases`, `gating_failures`, and
`observation_failures` retain the reasons these claims differ. Prerequisite and
inventory records are not coverage cases. Exit status 0 reports successful
profile execution, 1 reports gating failures, and 2 reports fatal configuration
or no executed case. A successful profile with capability or draft skips is
explicitly incomplete coverage, not a full-conformance certificate.

Isolated probes on 22 September 2026 found that the installed gfortran 16.1,
Flang 22 development build, and LFortran 0.66 development build reject even a
`GENERIC` function with no generic dummy. They also lack `TYPEOF`, `RANK`
clauses, `ISO_FORTRAN_ENV`'s `MAX_RANK`, and `DEFAULT KIND`. Their rejection of
a new-syntax negative is therefore not evidence for that fixture's intended
rule and must not be counted as a pass.

Until the runner's feature prerequisite and diagnostic gating show that the
intended rule was reached, repeated full-suite attempts with those compilers
add no feature-level evidence. The runner regressions include native
status-zero `ERROR STOP`, completion-marker rejection, ordinary matrix-copy
residuals, and mixed C/Fortran linking. The ordinary array-domains control
runs on all three installed compilers. The faithful internal-procedure
identity control passes gfortran but exposes baseline defects in Flang and
LFortran; it is not weakened to hide those defects.

No `GENERIC` fixture execution or real multi-image coarray execution is
validated locally. The self-tests, metadata checks, ordinary controls, and
manually expanded specializations validate the harness or ordinary semantics
only. The coverage matrix records those validation boundaries and the
conservative intrinsic-signature diagnostic classification separately.
