# Conformance coverage matrix

This matrix maps draft requirements to durable fixture evidence. It complements
the language guide; it is not a per-compiler fixture result log.

## How to read the matrix

- **Run** means the fixture is intended to compile, link, and execute its
  checks. It does not claim that the fixture ran on every local compiler.
- **Compile** means successful translation is the relevant check; **diagnostic**
  means the intended phase and diagnostic must be identified.
- **Processor profile** means execution depends on an optional processor
  capability such as a named kind, character set, rank, coarray mode, or
  launcher.
- **Draft reading** means non-gating by default. `--gate-drafts` can make an
  explicitly selected reading profile-gating, but either result remains neutral
  with respect to settled standard conformance.

The mutually exclusive `character-generic-parse` and
`character-ordinary-parse` readings may be selected together only for
non-gating comparison; the runner forbids gating both in one profile.

The `TEST-RULE`, `TEST-REQUIRES`, `TEST-DRAFT`, and
`TEST-DIAGNOSTIC-CLASS` headers in the fixture are the machine-readable source
of truth. This document groups them for humans and must be reconciled with
those headers whenever fixtures move.

## Inventory

The reconciled suite has 267 cases in 278 Fortran source files:

| Category | Cases |
| --- | ---: |
| Positive (`valid` category) | 74 |
| Compile-time diagnostic | 191 |
| Expected runtime termination | 2 |
| **Total** | **267** |

Twenty-three cases are draft-tagged. One positive case,
`tests/valid/language_array_domains_expanded.f90`, is ordinary
manual-specialization control code rather than generic-subprogram execution.
Metadata validation reports zero errors and zero warnings.

## Settled positive behavior

| Requirement | Fixture evidence | Mode | Conditions or limitation |
| --- | --- | --- | --- |
| Intrinsic type and kind expansion; static type pruning (7.3.2.2, 11.1.11, 15.6.2.4) | `tests/valid/intrinsic_types.f90`, `integer_kinds.f90`, `real_complex_kinds.f90`, `logical_kinds.f90` | Run | Named-size kinds are processor-profile coverage; inventory-based cases cover all reported kinds. |
| Independent Cartesian factors and dependent properties (8.2 NOTE 1, 15.6.2.4 p1-p2) | `tests/valid/language_partial_dependencies.f90`, `cross_product.f90`, `dependent_mod.f90`, `standard_note_shapes.f90` | Run | The language fixture executes all 12 NOTE 1 combinations and the independent `TYPEOF(x), RANK(0:2)` case. |
| Semantic duplicate removal (7.3.2.2 p2-p3, 8.5.17 p4) | `tests/valid/language_kind_dedup.f90`, `language_rank_sets.f90`, `duplicate_type_kind.f90`, `duplicates_remain_generic.f90` | Run | Mixed assumed/deferred character-length duplicates are a quarantined reading, not settled coverage. |
| Parameterized derived types, defaults, inheritance, and generic kind parameters (C719-C723) | `tests/valid/language_pdt_defaults.f90`, `language_pdt_inheritance.f90`, `parameterized_derived.f90`, `pdt_scalar_kind.f90`, `pdt_deferred_length.f90` | Run | Assumed-length guard syntax is separately quarantined. |
| Generic rank, bounds, implied-shape constants, allocatable/pointer dummies, and results (8.5.17, C875-C877) | `tests/valid/language_rank_sets.f90`, `rank_bounds_and_result.f90`, `rank_allocatable_pointer.f90`, `integration_allocatable_pointer_results.f90` | Run | Ranks above the literal portable limit are not part of the default conformance gate. |
| Ordinary array domains versus rank-generic dummies | `tests/valid/language_array_domains.f90` | Run | Covers explicit/assumed shape, assumed size, assumed rank with runtime `SELECT RANK`, rank-generic `CLASS(*)`, and permitted inquiry/common-body use of rank-generic `TYPE(*)`. |
| Manual explicit-specialization control for array domains | `tests/valid/language_array_domains_expanded.f90` | Run control | Validates ordinary compiler/runtime and harness behavior only; it is not a generic-subprogram fixture pass. |
| Static generic selection, ranges/lists, defaults in any order, empty constructs, pruning, names, and named `EXIT` (11.1.10-11.1.11) | `tests/valid/language_selection_control.f90`, `language_selection_order.f90`, `select_rank_default.f90`, `select_rank_gaps.f90`, `construct_name.f90`, `branch_to_end_select.f90` | Run | Out-of-set blocks are pruned; no runtime `IF` is used as a substitute. |
| Declared-type selection, defaults, and scoped default-kind matching (8.7, 11.1.11) | `tests/valid/language_parsing_scoping.f90`, `language_pdt_defaults.f90`, `select_type_default.f90`, `declared_type_default_kind.f90`, `nested_select.f90` | Run | Assumed-length guard cases use a draft-reading profile. |
| Character generic forms and entity length overrides | `tests/valid/language_character_forms.f90`, `character_kinds.f90` | Run | Requires the reported character-kind count; ambiguous bare assumed-length declarations are excluded from this settled core. |
| `TYPE`, `CLASS`, extensibility, enum/enumeration domains, dynamic type, and `CLASSOF` | `tests/valid/language_type_domains.f90`, `derived_and_class.f90`, `classof_dependent.f90`, `enumeration_types.f90`, `enum_bind_c.f90` | Run | `CLASS` lists are limited to extensible declared types by C715. |
| Separate attribute statements and specialization-dependent specification expressions | `tests/valid/language_specification_processing.f90` | Run | Combines `DIMENSION`, `ALLOCATABLE`, `POINTER`, and `INTENT` with generic/dependent declarations. |
| Prefixes, elemental resolution, recursion, and calls between specifics | `tests/valid/prefixes.f90`, `elemental.f90`, `elemental_tie_break.f90`, `factorial.f90`, `call_other_specific.f90` | Run | Every generated specific must satisfy the applicable prefix requirements. |
| Per-specific saved state and internal procedures | `tests/valid/save_per_specific.f90`, `internal_host.f90` | Run | Shared physical code is allowed only if these identities and state partitions are preserved. |
| Explicit-interface dummy procedures and dependent result characteristics | `tests/valid/dummy_procedure.f90`, `rank_bounds_and_result.f90`, `integration_allocatable_pointer_results.f90` | Run | C1585 and C877 remain independently applicable. |
| Generic extension, intrinsic/host fallback, constructor association, operators, assignment, and defined I/O | `tests/valid/integration_name_resolution.f90`, `extend_generic.f90`, `extend_intrinsic.f90`, `operator_and_assignment.f90`, `defined_io.f90` | Run | `defined_io.f90` executes formatted/unformatted read and write for every contributed declared type. |
| Host/use association, `ONLY` renaming, accessibility, merged generics, and separate compilation | `tests/valid/integration_name_resolution.f90`, `module_use.f90`, `separate_compilation/` | Run | Includes two modules renamed to one local generic identifier and access through private type metadata. |
| Separate and submodule procedures | `tests/valid/integration_module_interface_singleton/`, `submodule_procedure.f90` | Run | The singleton interface has no generic declaration and is settled. Expanding interface bodies are quarantined. |
| Allocation, finalization, and polymorphic dynamic type after selection | `tests/valid/integration_finalization_polymorphism.f90` | Run | Exercises per-specific `INTENT(OUT)` finalization and rank-generic polymorphic allocation. |
| Optional/keyword association and dependent dummies | `tests/valid/integration_keyword_optional.f90`, `language_partial_dependencies.f90` | Run | Ordinary argument association still applies after specific selection. |
| Generic with no generic dummy | `tests/valid/no_generic_dummy.f90` | Run | One unnamed specific; the identifier remains generic. |

## Settled required diagnostics

These rows represent numbered syntax rules, constraints, or the explicit
detect-and-report classes in 4.2. The conformance profile verifies the intended
diagnostic; unsuccessful translation is a stricter policy.

| Requirement group | Fixture evidence | Mode |
| --- | --- | --- |
| Generic declaration placement and one nonoptional dummy (C801-C804) | `tests/invalid_compile_time/not_in_generic_subprogram.f90`, `generic_local.f90`, `generic_result.f90`, `two_objects.f90`, `optional_dummy.f90`, and the `reject_generic_decl_*`, `reject_rank_generic_*`, and character-length cases | Diagnostic |
| Generic type/kind syntax, unsupported kinds, and PDT constraints (C707, C715-C723, 4.2(4)) | Existing type/PDT negatives plus `reject_kind_nonconstant_array.f90`, `reject_kind_noninteger_array.f90`, `reject_kind_rank_two.f90`, `reject_kind_unsupported_value.f90`, `reject_pdt_*`, and `reject_type_abstract.f90` | Diagnostic |
| Rank bounds, `DIMENSION` conflicts, array-spec exclusion, and C877 | Existing rank negatives plus `reject_rank_*` and `reject_rank_dependent_plain_result.f90` | Diagnostic |
| Assumed-type and assumed-rank name-use restrictions (C725, C845) | `reject_assumed_type_select_generic_rank.f90`, `reject_assumed_rank_select_generic_type.f90` | Diagnostic |
| `SELECT GENERIC` syntax, selector, default, duplicate-guard, and construct-name constraints | Existing selection negatives plus `reject_select_*`, `reject_duplicate_guard_*`, `reject_rank_*name*`, and `reject_type_*name*` | Diagnostic |
| Generic prefix placement, nesting, alternate returns, dummy interfaces, and `ENTRY` (C1564, C1582-C1585, C1589) | `external_subprogram.f90`, `abstract_interface.f90`, `nested_generic.f90`, `alternate_return.f90`, `implicit_interface_dummy.f90`, `entry_statement.f90` | Diagnostic |
| Generic-name uses, duplicate insertion, procedure-interface conflicts, and `C_FUNLOC` | Existing generic-name negatives plus `reject_duplicate_*insertion.f90`, `reject_generic_procedure_interface.f90`, and `reject_generic_c_funloc.f90` | Diagnostic |
| Prefix, elemental, and distinguishability constraints | Existing prefix negatives plus `reject_duplicate_generic_prefix.f90`, `reject_impure_pure_prefix.f90`, `reject_recursive_nonrecursive_prefix.f90`, `reject_elemental_*`, and `reject_generic_*ambiguity*.f90` | Diagnostic |
| Operator, assignment, and defined-I/O pairwise constraints | `reject_operator_ambiguous.f90`, `reject_assignment_ambiguous.f90`, `reject_defined_io_ambiguous.f90` | Diagnostic |
| Separate-module semantic correspondence | `reject_separate_attribute_mismatch/`, `reject_separate_dummy_name_mismatch/`, `reject_separate_nonrecursive_mismatch/`, `reject_separate_result_mismatch/` | Diagnostic |
| Draft syntax versus the superseded edit paper | `type_is_syntax.f90`, `type_default_syntax.f90`, `rankof_syntax.f90`, `open_rank_range.f90`, `star_all_kinds.f90` | Diagnostic |

## Enhanced diagnostics and runtime termination

| Requirement | Fixture evidence | Mode | Default treatment |
| --- | --- | --- | --- |
| Every residual specific conforms; runtime `IF` does not prune | `tests/invalid_compile_time/mod_requires_same_kind.f90`, `reject_constant_if_not_pruned.f90`, `reject_selected_generic_block_invalid.f90`, `reject_unused_specific_invalid.f90` | Enhanced diagnostic | Optional enhanced profile unless another numbered constraint independently applies. |
| `NON_RECURSIVE` cannot call another specific directly or indirectly (15.6.2.1 p3) | `non_recursive_calls_specific.f90`, `reject_nonrecursive_indirect_cycle.f90` | Enhanced diagnostic | Optional enhanced profile. |
| At most one selected block; no branch into a generic selection | `overlapping_rank_guards.f90`, `branch_into_select.f90`, `reject_branch_into_select_type.f90` | Enhanced diagnostic | Optional enhanced profile. |
| Ordinary call-association requirements after selection | `reject_call_allocatable_requirement.f90`, `reject_call_pointer_requirement.f90`, `reject_call_intent_out_expression.f90`, `reject_call_*no_match.f90` | Enhanced diagnostic | Optional enhanced profile unless a numbered constraint independently applies. |
| Operator/assignment/defined-I/O eligibility of every generated specific | `reject_operator_*`, `reject_assignment_*`, `reject_defined_io_*`, `reject_read_*`, `reject_write_*` | Enhanced diagnostic | Pairwise ambiguity constraints remain required where separately tagged. |
| Conforming `ERROR STOP` paths | `tests/invalid_runtime/factorial_negative.f90`, `integration_rank_error_stop.f90` | Run, expected error termination | Marker is flushed before termination; calibration uses each case's literal stop-code form and literal `QUIET=` value, with no fixed message or exit-code range. |

## Processor-profile coverage

| Capability | Evidence | Treatment |
| --- | --- | --- |
| Every reported integer, real/complex, logical, and character kind | Inventory-driven generated calls plus the kind-family fixtures above | Runs every reported kind and checks independent kind/type/rank saved state plus the joint type/kind/rank product; kind zero is valid. |
| Named `INT32`, `INT64`, `REAL32`, `REAL64`, ASCII, ISO 10646, and additional widths | Capability metadata on fixtures that mention them | Explicit run or explicit capability skip; never a runtime-`IF` workaround. |
| Coarrays and multiple images | `tests/valid/coarray_rank.f90`, `integration_coarray_multi_image.f90` | Requires the appropriate compiler mode and, for the integration fixture, a configured two-image launcher. |
| `MAX_RANK(corank)` support query | `tests/valid/coarray_rank.f90` | Accepts a supported nonnegative result for corank 16; requires `-HUGE(0_STANDARD_INTEGER)` only when that corank is unsupported. It does not impose a universal corank-16 limit. |
| Literal portable ranks | Rank fixtures plus generated calls for every specific from rank 0 through the bound, each called twice | Default conformance profile, bounded by both C875 and the written C826 limit. |
| Processor-advertised ranks above 15 | `tests/valid/integration_extended_rank_limit.f90`, the paired quarantined negative, and generated calls through `MAX_RANK()` | Opt-in and non-gating by default; `--gate-drafts` may make the selected profile gating. |

## Quarantined draft readings

No result in this table, in either direction, is by itself a compiler
conformance failure.

| Draft-reading ID | Wording tension | Fixture evidence |
| --- | --- | --- |
| `generic-interface-declarations` | C801 says a generic declaration appears only in a generic subprogram, while 15.4.3.2 p4 and 15.4.3.4.1 p2 describe `MODULE GENERIC` interface bodies and their expanded contribution. | `tests/valid/integration_module_interface_routes/`, `separate_module_procedure.f90`, and tagged separate-interface mismatch cases. |
| `assumed-length-guards` | C1160 requires assumed length parameters, while C736, C7124, and 7.2 do not clearly permit `*` in a generic type guard. | Tagged character/PDT guard negatives in `tests/draft_interpretations/negative/` plus tagged C1160 cases under `invalid_compile_time/`. |
| `character-generic-parse` | `CHARACTER(LEN=*)` without a kind array is a singleton generic intrinsic spec. | `tests/draft_interpretations/valid/language_character_generic_parse.f90`, using `DECLARED TYPE DEFAULT` so the observation does not depend on assumed-length guard syntax. |
| `character-ordinary-parse` | The same declaration has the long-standing ordinary assumed-length parse and is not type-generic. | `tests/draft_interpretations/negative/select_on_assumed_character.f90`, likewise using a default guard to isolate parsing. |
| `empty-expansion` | No explicit requirement says a rank or kind set must be nonempty. | `tests/draft_interpretations/negative/empty_rank_range.f90`, `reject_empty_kind_set.f90`. |
| `generic-bind-c` | There is no blanket prohibition; singleton expansion, `NAME=""`, and internal procedures without a binding label differ from a multi-specific family with one nonempty label. | Positive observations: `tests/valid/integration_generic_bind_c_empty_name.f90`, `integration_generic_bind_c_singleton_label.f90`, `integration_generic_bind_c_internal.f90`. Negative observations: `tests/draft_interpretations/negative/bind_c_many_specifics.f90`, `bind_c_one_specific.f90`. |
| `extended-rank-limit` | C826 fixes rank plus corank at 15, while `MAX_RANK` describes processors supporting 24. | `tests/valid/integration_extended_rank_limit.f90`, `tests/draft_interpretations/negative/reject_rank_corank_sum_above_fifteen.f90`. |
| `mixed-length-dedup` | Duplicate type/kind removal does not say how to retain distinct assumed/deferred length modes. | `tests/draft_interpretations/negative/reject_mixed_length_mode_dedup.f90`. |
| `template-integration` | R1608 permits ordinary subprograms in a template subprogram part, while C1582 restricts generic subprograms to module or internal subprograms. | `tests/draft_interpretations/valid/language_template_integration.f90`. |
| `PROCEDURE_NAME` / UTI031 | Anonymous specifics leave the intrinsic result undefined by the draft. | No gating fixture; deliberately unresolved. |

## Local validation boundary

Isolated well-formed probes on 22 September 2026 showed that the installed
gfortran 16.1, Flang 22 development build, and LFortran 0.66 development build
reject a `GENERIC` function even when it has no generic dummy. Those
installations also lack `TYPEOF`, `RANK` clauses, `MAX_RANK` in
`ISO_FORTRAN_ENV`, and `DEFAULT KIND`.

The 25 runner self-tests pass, and
`tests/valid/language_array_domains_expanded.f90` compiles and runs with all
three installed compilers. No `GENERIC` fixture execution is validated
locally. Accordingly, this matrix records intended generic coverage, not local
feature execution. A generic-syntax rejection cannot satisfy an intended
negative-rule row unless prerequisite and diagnostic gating demonstrates that
the compiler reached that rule. Runner self-tests, metadata validation,
ordinary Fortran controls, and explicit hand-written specializations validate
the harness or ordinary semantics only.
