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
| `tests/valid/` | Conforming positive fixtures, including runtime, compile-only, capability-dependent, and multi-file cases as classified by the runner |
| `tests/invalid_compile_time/` | Settled negative cases and enhanced-diagnostic cases, classified by metadata |
| `tests/invalid_runtime/` | Conforming programs expected to initiate error termination |
| `tests/draft_interpretations/` | Explicitly quarantined draft readings |
| `tests/run.sh` | Stable runner entry point |

## Reconciled suite inventory

The integrated inventory on 22 September 2026 is:

| Category | Cases |
| --- | ---: |
| Positive cases (`valid` category) | 74 |
| Compile-time diagnostic cases | 191 |
| Expected runtime-termination cases | 2 |
| **Total** | **267** |

The cases contain 278 Fortran source files. Twenty-three cases carry
`TEST-DRAFT`; one positive case,
`valid/language_array_domains_expanded.f90`, is an explicitly ordinary
manual-specialization control rather than generic-subprogram execution.
`./tests/run.sh check` reports zero metadata errors and zero warnings.

The runner has a Python 3.9-compatible, standard-library-only backend. The
ordinary entry remains:

```sh
FC=lfortran FCFLAGS='...' ./tests/run.sh
```

Common metadata-only commands are:

```sh
./tests/run.sh --help
./tests/run.sh check
./tests/run.sh check invalid_compile_time/
./tests/run.sh list
./tests/run.sh list --json valid/
```

`check` validates fixture metadata without invoking a compiler. `list` reports
the discovered cases; selectors are relative to `tests/`.

The default execution profile is conformance mode. Strict mode additionally
requires unsuccessful rejection and enables enhanced-diagnostic cases:

```sh
FC=lfortran ./tests/run.sh --mode conformance valid/factorial.f90
FC=lfortran ./tests/run.sh --strict invalid_compile_time/
```

Draft readings are skipped by default. `--draft` selects one or more readings;
selected results remain non-gating unless `--gate-drafts` is also requested:

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
- A negative case passes only when the intended phase and diagnostic are
  verified. An unrelated parse error, missing-main link error, echoed source
  line, unknown diagnostic format, or absent output is not evidence for the
  expected rule.
- Processor capabilities and compiler feature support are different. Optional
  kinds, character sets, coarray launchers, image counts, and extended ranks
  can cause an explicit capability skip; absence of the generic-subprogram
  language feature is a failure, not a successful negative test.
- The runner probes the processor’s kind inventories and generates calls for
  every reported kind. Real-kind coverage includes both real and corresponding
  complex specifics. It also checks per-specific saved state independently by
  kind, type, rank, and the joint type/kind/rank product. A supported kind value
  may be zero.
- Generated rank coverage invokes every generic rank specific from zero through
  the selected portable or extended bound, twice for per-specific state. It
  does not treat successful construction of one ordinary high-rank array as
  coverage of all intervening generic specifics.
- Multi-image cases require a configured launcher. A missing launcher is
  reported as a skip, never as covered execution.
- Runtime error-termination cases print a `TEST-STOP:` marker, execute
  `FLUSH(output_unit)`, and then execute the intended `ERROR STOP`. The runner
  verifies the marker and calibrates the same literal stop-code form and
  literal `QUIET=` value with the same compiler, flags, and launcher; it does
  not assume one fixed message or status. The standard makes the externally
  observed status processor dependent, so there is no portable “1 through
  127” requirement.

Common metadata includes:

```fortran
! TEST-RULE: C802 15.6.2.4
! TEST-REQUIRES: int32 real64 ascii integer_kinds>=2
! TEST-DRAFT: character-generic-parse
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: nonoptional.*dummy
! TEST-ERROR-PHASE: compile
! TEST-ERROR-HERE
! TEST-STOP: factorial-negative
! TEST-IMAGES: 2
```

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
  semantically before the Cartesian product is formed. Equal sets on two
  different generic dummies remain independent factors.
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
  per-specific saved state, and internal-procedure identities are preserved.

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

Isolated probes on 22 September 2026 found that the installed gfortran 16.1,
Flang 22 development build, and LFortran 0.66 development build reject even a
`GENERIC` function with no generic dummy. They also lack `TYPEOF`, `RANK`
clauses, `ISO_FORTRAN_ENV`'s `MAX_RANK`, and `DEFAULT KIND`. Their rejection of
a new-syntax negative is therefore not evidence for that fixture's intended
rule and must not be counted as a pass.

Until the runner's feature prerequisite and diagnostic gating show that the
intended rule was reached, repeated full-suite attempts with those compilers
add no feature-level evidence. All 25 runner self-tests pass, and the ordinary
`valid/language_array_domains_expanded.f90` control compiles and runs with all
three installed compilers. No `GENERIC` fixture execution is validated
locally. The self-tests, metadata checks, ordinary controls, and manually
expanded specializations validate the harness or ordinary semantics only.
