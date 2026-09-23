# Conformance coverage matrix

This matrix maps draft requirements to durable fixture evidence. It complements
the language guide; it is not a per-compiler fixture result log.

## How to read the matrix

- **Run** means the fixture is intended to compile, link, and execute its
  checks. It does not claim that the fixture ran on every local compiler.
- **Diagnostic** means the intended compile or link phase and diagnostic must
  be identified. Positive fixtures are runtime cases, not compile-only cases.
- **Processor profile** means execution depends on an optional processor
  capability such as a named kind, character set, rank, coarray mode, or
  launcher.
- **Draft reading** means non-gating by default. `--gate-drafts` can make an
  explicitly selected reading profile-gating, but either result remains neutral
  with respect to settled standard conformance.

The mutually exclusive `character-generic-parse` and
`character-ordinary-parse` readings may be selected together only for
non-gating comparison; the runner forbids gating both in one profile.
The same distinction applies to `literal-rank-limit` and
`extended-rank-limit`.

The `TEST-RULE`, `TEST-REQUIRES`, `TEST-DRAFT`, `TEST-PASS`, and
`TEST-DIAGNOSTIC-CLASS` headers in the fixture are the machine-readable source
of truth. This document groups them for humans and must be reconciled with
those headers whenever fixtures move.

## Inventory

The reconciled suite has 358 cases in 383 Fortran source files and one
companion C source:

| Category | Cases |
| --- | ---: |
| Positive (`valid` category) | 104 |
| Compile-time diagnostic | 251 |
| Expected runtime termination | 3 |
| **Total** | **358** |

These counts exclude processor-generated cases and prerequisite records.

Twenty-four cases are draft-tagged. The positive cases
`tests/valid/language_array_domains_expanded.f90` and
`tests/valid/audit_language_identity_ordinary_control.f90` are ordinary
manual-specialization controls rather than generic-subprogram execution.
Compile-time negatives comprise 199 required-diagnostic and 52 enhanced
cases, including their draft observations. The runner's `check` command
validates metadata; it does not establish language conformance.

## Settled positive behavior

| Requirement | Fixture evidence | Mode | Conditions or limitation |
| --- | --- | --- | --- |
| Intrinsic type and kind expansion; static type pruning (7.3.2.2, 11.1.11, 15.6.2.4) | `tests/valid/intrinsic_types.f90`, `integer_kinds.f90`, `real_complex_kinds.f90`, `logical_kinds.f90` | Run | Named-size kinds are processor-profile coverage; inventory-based cases cover all reported kinds. |
| Independent Cartesian factors and dependent properties (8.2 NOTE 1, 15.6.2.4 p1-p2) | `tests/valid/language_partial_dependencies.f90`, `cross_product.f90`, `dependent_mod.f90`, `standard_note_shapes.f90` | Run | The language fixture executes all 12 NOTE 1 combinations and the independent `TYPEOF(x), RANK(0:2)` case. |
| Generic domains depending on earlier choices (R708, R833, 10.1.12, 15.6.2.4) | `tests/valid/audit_language_dependent_domains.f90`, `audit_language_dependent_kind_domains.f90` | Run | Executes all five dependent rank pairs without an optional-kind gate; the separate two-kind case checks per-choice domain deduplication. |
| Semantic duplicate removal (7.3.2.2 p2-p3, 8.5.17 p4) | `tests/valid/language_kind_dedup.f90`, `language_rank_sets.f90`, `duplicate_type_kind.f90`, `duplicates_remain_generic.f90` | Run | Mixed assumed/deferred character-length duplicates are a quarantined reading, not settled coverage. |
| Parameterized derived types, defaults, inheritance, and generic kind parameters (C719-C723) | `tests/valid/language_pdt_defaults.f90`, `language_pdt_inheritance.f90`, `parameterized_derived.f90`, `pdt_scalar_kind.f90`, `pdt_deferred_length.f90` | Run | Assumed-length guard syntax is separately quarantined. |
| Defaulted PDT parameters, multiple lengths, nondefault-integer-kind domain expressions, and array expressions | `tests/valid/audit_language_pdt_kind_domains.f90` | Run | Uses parameter inquiries rather than interpretation-dependent length guards; payloads remain representable even for narrow additional integer kinds. |
| Generic rank, bounds, implied-shape constants, allocatable/pointer dummies, and results (8.5.17, C875-C877) | `tests/valid/language_rank_sets.f90`, `rank_bounds_and_result.f90`, `rank_allocatable_pointer.f90`, `integration_allocatable_pointer_results.f90` | Run | Ranks above the literal portable limit are not part of the default conformance gate. |
| Explicit character/PDT lengths when only rank is generic (C717, C804, 8.2) | `tests/valid/audit_language_rank_only_explicit_lengths.f90` | Run | Distinguishes ordinary explicit type parameters from the restrictions on generic type specifiers and entity length overrides. |
| Ordinary array domains versus rank-generic dummies | `tests/valid/language_array_domains.f90` | Run | Covers explicit/assumed shape, assumed size, assumed rank with runtime `SELECT RANK`, rank-generic `CLASS(*)`, and permitted inquiry/common-body use of rank-generic `TYPE(*)`. |
| Manual explicit-specialization control for array domains | `tests/valid/language_array_domains_expanded.f90` | Run control | Validates ordinary compiler/runtime and harness behavior only; it is not a generic-subprogram fixture pass. |
| Static generic selection, ranges/lists, defaults in any order, empty constructs, pruning, names, and named `EXIT` (11.1.10-11.1.11) | `tests/valid/language_selection_control.f90`, `language_selection_order.f90`, `select_rank_default.f90`, `select_rank_gaps.f90`, `construct_name.f90`, `branch_to_end_select.f90` | Run | Out-of-set blocks are pruned; no runtime `IF` is used as a substitute. |
| Rank-specific named `EXIT`, unreachable overlap, and nested semantic pruning | `tests/valid/audit_language_select_control.f90` | Run | Covers overlapping guards whose intersection is outside the selector's domain and removal of purity, specification, name-use, and nested-selector violations in unselected outer blocks. |
| Declared-type selection, defaults, and scoped default-kind matching (8.7, 11.1.11) | `tests/valid/language_parsing_scoping.f90`, `language_pdt_defaults.f90`, `select_type_default.f90`, `declared_type_default_kind.f90`, `nested_select.f90` | Run | Assumed-length guard cases use a draft-reading profile. |
| `USE ... DEFAULT_KINDS`, complex defaults, and interface-scope resets | `tests/valid/audit_integration_default_kinds.f90`, `audit_integration_default_kinds_logical.f90`, `audit_integration_default_kinds_character.f90` | Run | Logical/character multi-kind observations are separate capability-dependent cases, not gates on the portable real/integer checks. |
| Character generic forms and entity length overrides | `tests/valid/language_character_forms.f90`, `character_kinds.f90` | Run | Arbitrary second-kind payloads are constructed in that kind, with disclosed ordinal-zero fallback for opaque repertoires; no unsupported cross-kind literal assignment. |
| `TYPE`, `CLASS`, extensibility, enum/enumeration domains, dynamic type, and `CLASSOF` | `tests/valid/language_type_domains.f90`, `derived_and_class.f90`, `classof_dependent.f90`, `enumeration_types.f90`, `enum_bind_c.f90` | Run | `CLASS` lists are limited to extensible declared types by C715. |
| Separate attribute statements and specialization-dependent specification expressions | `tests/valid/language_specification_processing.f90` | Run | Combines `DIMENSION`, `ALLOCATABLE`, `POINTER`, and `INTENT` with generic/dependent declarations. |
| Dependent declaration eligibility, implicit typing, specification functions, and `CLASSOF` | `tests/valid/audit_language_typeof_classof.f90` | Run | Includes valid implicitly established forward type and runtime specification bounds without treating runtime values as constants. |
| Prefixes, elemental resolution, recursion, and calls between specifics | `tests/valid/prefixes.f90`, `elemental.f90`, `elemental_tie_break.f90`, `factorial.f90`, `call_other_specific.f90` | Run | Every generated specific must satisfy the applicable prefix requirements. |
| Per-specific saved state and internal procedures | `tests/valid/save_per_specific.f90`, `internal_host.f90` | Run | Shared physical code is allowed only if these identities and state partitions are preserved. |
| Complete specialization-state key and nonfactors | `tests/valid/audit_language_save_identity.f90` | Run | Interleaved multi-dummy and PDT-kind tuples; explicit/declaration-initialized/DATA/allocatable/pointer saved state; length, shape, bounds, and dynamic type do not add state factors. |
| Local type identity and live internal host capture | `tests/valid/audit_language_specialization_identity.f90` | Run | Observes non-`SEQUENCE` local types and live parent/ancestor callbacks, including recursive instances of one specific. The ordinary control does not count as generated coverage. |
| Explicit-interface dummy procedures and dependent result characteristics | `tests/valid/dummy_procedure.f90`, `rank_bounds_and_result.f90`, `integration_allocatable_pointer_results.f90` | Run | C1585 and C877 remain independently applicable. |
| Automatic arrays, PDT lengths, polymorphic/procedure-pointer results, and elemental result parameters | `tests/valid/audit_integration_result_forms.f90`, `audit_integration_elemental_result_params.f90` | Run | Plain array results use explicit array specifications, not a forbidden plain-result `RANK` clause; result parameters are checked after specific selection. |
| Generic extension, intrinsic/host fallback, constructor association, operators, assignment, and defined I/O | `tests/valid/integration_name_resolution.f90`, `extend_generic.f90`, `extend_intrinsic.f90`, `operator_and_assignment.f90`, `defined_io.f90` | Run | `defined_io.f90` executes formatted/unformatted read and write for every contributed declared type. |
| `PROCEDURE` family-name contribution route, distinct from `GENERIC` statements | `tests/valid/audit_routes_operator_assignment.f90`, `audit_routes_defined_io.f90` | Run | Exercises generated unary/binary operators, assignment, and all four I/O interfaces, including permitted `VALUE` alternatives and actual-value preservation. |
| Existing named specific sharing the extended generic's identifier | `tests/valid/audit_integration_same_name_specific.f90` | Run | Specific actual/interface/pointer/type-bound contexts, renaming, and noninteroperable `C_FUNLOC` round trip still address the named specific, not an anonymous alternative. |
| Host/use association, `ONLY` renaming, accessibility, merged generics, and separate compilation | `tests/valid/integration_name_resolution.f90`, `module_use.f90`, `separate_compilation/` | Run | Includes two modules renamed to one local generic identifier and access through private type metadata. |
| Specific state shared across independently compiled callers and reexports | `tests/valid/audit_integration_separate_save_state/` | Run | Two caller objects reach the same generated state through distinct import paths; no cross-vendor object ABI is assumed. |
| Separate and submodule procedures | `tests/valid/integration_module_interface_singleton/`, `submodule_procedure.f90` | Run | The singleton interface has no generic declaration and is settled. Expanding interface bodies are quarantined. |
| Separate-interface assignment and defined-I/O contribution | `tests/valid/audit_integration_separate_io_singleton/` | Run | Settled singleton interfaces avoid C801's declaration conflict. Expanding routes are separately draft-tagged. |
| Allocation, finalization, and polymorphic dynamic type after selection | `tests/valid/integration_finalization_polymorphism.f90` | Run | Exercises per-specific `INTENT(OUT)` finalization and rank-generic polymorphic allocation. |
| Rank-dependent finalization and purity effects | `tests/valid/audit_integration_rank_finalization.f90` | Run | Checks the applicable scalar/array finalization and elemental entry behavior; negative companions exercise impure finalization and polymorphic-result constraints. |
| Optional/keyword association and dependent dummies | `tests/valid/integration_keyword_optional.f90`, `language_partial_dependencies.f90` | Run | Ordinary argument association still applies after specific selection. |
| Pointer/allocatable overloads, optional forwarding, and conditional arguments | `tests/valid/audit_integration_alloc_pointer_optional.f90`, `audit_integration_conditional_args.f90` | Run | Covers target-to-`INTENT(IN)` pointer association, absent/null/unallocated optional actuals, and `.NIL.` only for eligible optional dummies. |
| Additional dummy attributes | `tests/valid/audit_integration_attribute_preservation.f90`, `audit_integration_coarray_volatile.f90` | Run | Preserves `ASYNCHRONOUS`, `VOLATILE`, and `PROTECTED_TARGET` behavior; absence of a multi-image launcher is not needed for single-image checks. |
| PDT kind families in defined I/O | `tests/valid/audit_integration_dtio_pdt_family.f90` | Run | Type/kind-specific I/O contribution with ordinary permitted length parameters. |
| Generic with no generic dummy | `tests/valid/no_generic_dummy.f90` | Run | One unnamed specific; the identifier remains generic. |

## Settled required diagnostics

These rows represent numbered syntax rules, constraints, or the explicit
detect-and-report classes in 4.2. The conformance profile verifies the intended
diagnostic; unsuccessful translation is a stricter policy.

| Requirement group | Fixture evidence | Mode |
| --- | --- | --- |
| Generic declaration placement and one nonoptional dummy (C801-C804) | `tests/invalid_compile_time/not_in_generic_subprogram.f90`, `generic_local.f90`, `generic_result.f90`, `two_objects.f90`, `optional_dummy.f90`, and the `reject_generic_decl_*`, `reject_rank_generic_*`, and character-length cases | Diagnostic |
| Generic type/kind syntax, unsupported kinds, and PDT constraints (C707, C715-C723, 4.2(4)) | Existing type/PDT negatives plus `reject_kind_nonconstant_array.f90`, `reject_kind_noninteger_array.f90`, `reject_kind_rank_two.f90`, `reject_kind_unsupported_value.f90`, `reject_pdt_*`, and `reject_type_abstract.f90` | Diagnostic |
| Dependent declaration eligibility and generated component representation (C709-C714, C727) | `tests/invalid_compile_time/audit_reject_typeof_*`, `audit_reject_classof_*`, `audit_reject_generated_pdt_component_kind.f90` | Diagnostic |
| Rank bounds, `DIMENSION` conflicts, array-spec exclusion, and C877 | Existing rank negatives plus `reject_rank_*` and `reject_rank_dependent_plain_result.f90` | Diagnostic |
| Assumed-type and assumed-rank name-use restrictions (C725, C845) | `reject_assumed_type_select_generic_rank.f90`, `reject_assumed_rank_select_generic_type.f90` | Diagnostic |
| `SELECT GENERIC` syntax, selector, default, duplicate-guard, and construct-name constraints | Existing selection negatives plus `reject_select_*`, `reject_duplicate_guard_*`, `reject_rank_*name*`, and `reject_type_*name*` | Diagnostic |
| Guard expression forms, aliases, and retained residual violations | `audit_reject_rank_guard_*`, `audit_reject_duplicate_alias_type_guards.f90`, `audit_reject_selected_*` | Diagnostic |
| Explicit, deferred, or omitted/defaulted guard lengths (C1160) | `declared_type_explicit_len.f90`, `pdt_guard_colon.f90`, `reject_guard_character_missing_length.f90`, `reject_guard_pdt_missing_length.f90` under `invalid_compile_time/` | Diagnostic; no draft gate |
| Generic prefix placement, nesting, alternate returns, dummy interfaces, and `ENTRY` (C1564, C1582-C1585, C1589) | `external_subprogram.f90`, `abstract_interface.f90`, `nested_generic.f90`, `alternate_return.f90`, `implicit_interface_dummy.f90`, `entry_statement.f90` | Diagnostic |
| Generic-name uses, duplicate insertion, procedure-interface conflicts, and `C_FUNLOC` | Existing generic-name negatives plus `reject_duplicate_*insertion.f90`, `reject_generic_procedure_interface.f90`, and `reject_generic_c_funloc.f90` | Diagnostic |
| Prefix, elemental, and distinguishability constraints | Existing prefix negatives plus `reject_duplicate_generic_prefix.f90`, `reject_impure_pure_prefix.f90`, `reject_recursive_nonrecursive_prefix.f90`, `reject_elemental_*`, and `reject_generic_*ambiguity*.f90` | Diagnostic |
| Operator, assignment, and defined-I/O pairwise constraints | `reject_operator_ambiguous.f90`, `reject_assignment_ambiguous.f90`, `reject_defined_io_ambiguous.f90` | Diagnostic |
| Generated-family distinguishability and duplicate insertion (C1511-C1517) | `reject_generic_*ambiguity*.f90`, `reject_generic_{result_only,length_only,function_subroutine,assumed_rank_overlap,alloc_pointer_intent_in}.f90`, `reject_duplicate_*insertion.f90` | Diagnostic; these now contain generated families rather than only traditional named specifics |
| Separate-module semantic correspondence | `reject_separate_attribute_mismatch/`, `reject_separate_dummy_name_mismatch/`, `reject_separate_nonrecursive_mismatch/`, `reject_separate_result_mismatch/` | Diagnostic |
| Further result/default-kind correspondence and duplicate explicit binding labels | `integration_reject_separate_result_*`, `integration_reject_separate_default_kind_mismatch.f90`, `route_reject_generic_bind_c_shared_label.f90` | Diagnostic; correlated generic declarations and binding-label interface observations are separately tagged where needed |
| Conditional argument, elemental result, finalization/purity, and additional attribute constraints | `integration_reject_conditional_*`, `integration_reject_elemental_*`, `integration_reject_pure_*`, `integration_reject_protected_target_*`, `integration_reject_asynchronous_contiguous_section.f90`, `integration_reject_volatile_pure_generic.f90` | Diagnostic |
| Required defined-I/O type and length constraints (C1236-C1237) | `integration_reject_dtio_type_extensible.f90`, `integration_reject_dtio_pdt_explicit_length.f90` | Diagnostic |
| Draft syntax versus the superseded edit paper | `type_is_syntax.f90`, `type_default_syntax.f90`, `rankof_syntax.f90`, `open_rank_range.f90`, `star_all_kinds.f90` | Diagnostic |

## Enhanced diagnostics and runtime termination

| Requirement | Fixture evidence | Mode | Default treatment |
| --- | --- | --- | --- |
| Every residual specific conforms; runtime `IF` does not prune | `tests/invalid_compile_time/mod_requires_same_kind.f90`, `reject_constant_if_not_pruned.f90`, `reject_selected_generic_block_invalid.f90`, `reject_unused_specific_invalid.f90` | Enhanced diagnostic | Conservative intrinsic-signature policy; see the guide's explicit 4.2(7) assessment. Their source nonconformance is settled, not every diagnostic obligation. |
| `NON_RECURSIVE` cannot call another specific directly or indirectly (15.6.2.1 p3) | `non_recursive_calls_specific.f90`, `reject_nonrecursive_indirect_cycle.f90` | Enhanced diagnostic | Optional enhanced profile. |
| At most one selected block; no branch into a generic selection | `overlapping_rank_guards.f90`, `branch_into_select.f90`, `reject_branch_into_select_type.f90` | Enhanced diagnostic | Optional enhanced profile. |
| Ordinary call-association requirements after selection | `reject_call_allocatable_requirement.f90`, `reject_call_pointer_requirement.f90`, `reject_call_intent_out_expression.f90`, `reject_call_*no_match.f90` | Enhanced diagnostic | Optional enhanced profile unless a numbered constraint independently applies. |
| Dependent-domain rejection and explicit callback characteristics | `audit_reject_dependent_rank_pair.f90`, `integration_reject_callback_{kind,rank,purity}_mismatch.f90` | Enhanced diagnostic | Wrong actual/interface characteristics do not become allowed after selecting a specific. |
| Operator/assignment/defined-I/O eligibility of every generated specific | `reject_operator_*`, `reject_assignment_*`, `reject_defined_io_*`, `reject_read_*`, `reject_write_*` | Enhanced diagnostic | Pairwise ambiguity constraints remain required where separately tagged. |
| Conforming `ERROR STOP` paths | `tests/invalid_runtime/factorial_negative.f90`, `integration_rank_error_stop.f90`, `audit_integration_coarray_error_stop.f90` | Run, expected error termination | Markers are flushed; calibration matches literal stop code, `QUIET`, image count, and declared stopping image rather than imposing a fixed exit-code range. The multi-image case also needs a configured launcher. |

## Processor-profile coverage

| Capability | Evidence | Treatment |
| --- | --- | --- |
| Every reported integer, real/complex, logical, and character kind | Inventory-driven generated calls plus the kind-family fixtures above | Boundary/sign/precision/boolean payloads, scalar/vector/matrix state, and matrix copies; kind zero is valid. Known character repertoires get nonzero ordinals; opaque extra kinds have explicit ordinal-zero fallback, not an invented repertoire/width guarantee. |
| Named `INT32`, `INT64`, `REAL32`, `REAL64`, ASCII, ISO 10646, and additional widths | Capability metadata on fixtures that mention them | Explicit run or explicit capability skip; never a runtime-`IF` workaround. |
| Coarrays and multiple images | `tests/valid/coarray_rank.f90`, `integration_coarray_multi_image.f90`, `audit_integration_coarray_rank13_corank2.f90`, `audit_integration_coarray_remote_rank.f90`, `audit_integration_coarray_volatile.f90` | Adds corank-two boundary/intermediate ranks, remote arrays and allocatable descriptors; configured compiler mode and a launcher are required where tagged. |
| `MAX_RANK(corank)` support query | `tests/valid/coarray_rank.f90` | Accepts a supported nonnegative result for corank 16; requires `-HUGE(0_STANDARD_INTEGER)` only when that corank is unsupported. It does not impose a universal corank-16 limit. |
| Literal portable ranks | Rank fixtures plus the always-gating `@generated/processor-rank` calls for every rank 0 through 15 | Repeated state checks, outermost-axis payloads, and dimension-one stride-two actuals. Layout/active-axis details are explicit, not a claim to all stride combinations; invalid reported minima fail rather than shrinking coverage. |
| Processor-advertised ranks above 15 | `tests/valid/integration_extended_rank_limit.f90` and separate `@generated/processor-rank-extended` calls through `MAX_RANK()` | Opt-in under `extended-rank-limit`; unavailable capability is an explicit skip. Portable generated coverage remains gating. The opposing negative is under `literal-rank-limit`, not this acceptance profile. |
| Companion C interoperability | `tests/valid/audit_integration_bind_c_abi/` | A native C source calls the explicit singleton binding label and checks argument/result ABI; requires the selected `generic-bind-c` reading and a working configured C compiler. |

## Quarantined draft readings

No result in this table, in either direction, is by itself a compiler
conformance failure.

| Draft-reading ID | Wording tension | Fixture evidence |
| --- | --- | --- |
| `generic-interface-declarations` | C801 says a generic declaration appears only in a generic subprogram, while 15.4.3.2 p4 and 15.4.3.4.1 p2 describe `MODULE GENERIC` interface bodies and their expanded contribution. | `tests/valid/integration_module_interface_routes/`, `separate_module_procedure.f90`, `audit_integration_separate_io_routes/`, and tagged separate-interface/correlation mismatch cases. |
| `assumed-length-guards` | C1160 requires assumed length parameters, while C736, C7124, and 7.2 do not clearly permit `*` in a generic type guard. | `tests/draft_interpretations/valid/language_assumed_length_guards.f90` has portable default-character/PDT checks; `language_assumed_length_guards_character_kinds.f90` separately requires multiple character kinds. C1160 explicit/deferred/omitted-length negatives are settled and not tagged. |
| `character-generic-parse` | `CHARACTER(LEN=*)` without a kind array is a singleton generic intrinsic spec. | `tests/draft_interpretations/valid/language_character_generic_parse.f90`, using `DECLARED TYPE DEFAULT` so the observation does not depend on assumed-length guard syntax. |
| `character-ordinary-parse` | The same declaration has the long-standing ordinary assumed-length parse and is not type-generic. | `tests/draft_interpretations/negative/select_on_assumed_character.f90`, likewise using a default guard to isolate parsing. |
| `empty-expansion` | No explicit requirement says a rank or kind set must be nonempty. | `tests/draft_interpretations/negative/empty_rank_range.f90`, `reject_empty_kind_set.f90`. |
| `generic-bind-c` | There is no blanket prohibition; singleton expansion, `NAME=""`, and internal procedures without a binding label differ from a multi-specific family with one nonempty label. | Positive observations include `tests/valid/integration_generic_bind_c_{empty_name,singleton_label,internal}.f90` and `audit_integration_bind_c_abi/`. Implicit-label negatives and separate binding-label correspondence are tagged; the duplicate explicit nonempty-label negative is independently covered under 20.2. |
| `extended-rank-limit` | C826 fixes rank plus corank at 15, while `MAX_RANK` describes processors supporting 24. | `tests/valid/integration_extended_rank_limit.f90` and extended generated ranks observe acceptance. |
| `literal-rank-limit` | Alternative observation of the written C826 bound, distinct from extended-rank acceptance. | `tests/draft_interpretations/negative/reject_rank_corank_sum_above_fifteen.f90` observes diagnosis; both rank readings can be observed, but not gated together. |
| `mixed-length-dedup` | Duplicate type/kind removal does not say how to retain distinct assumed/deferred length modes. | `tests/draft_interpretations/negative/reject_mixed_length_mode_dedup.f90`. |
| `template-integration` | R1608 permits ordinary subprograms in a template subprogram part, while C1582 restricts generic subprograms to module or internal subprograms. | `tests/draft_interpretations/valid/language_template_integration.f90`. |
| `PROCEDURE_NAME` / UTI031 | Anonymous specifics leave the intrinsic result undefined by the draft. | No gating fixture; deliberately unresolved. |

## Local validation boundary

Isolated well-formed probes on 22 September 2026 showed that the installed
gfortran 16.1, Flang 22 development build, and LFortran 0.66 development build
reject a `GENERIC` function even when it has no generic dummy. Those
installations also lack `TYPEOF`, `RANK` clauses, `MAX_RANK` in
`ISO_FORTRAN_ENV`, and `DEFAULT KIND`.

The harness regressions cover status-zero assertion failure, status-zero
expected error termination, diagnostic-only compilation without an object,
invalid rank inventory, selected draft execution, profile versus coverage
reporting, companion C compilation, and ordinary matrix-copy residuals.
`./tests/run.sh self-test` reports the current regression inventory; it is not
a language-feature run.

| Ordinary validation evidence | Observed boundary |
| --- | --- |
| `language_array_domains_expanded.f90` through the runner | Passes gfortran, Flang, and LFortran. |
| Faithful `audit_language_identity_ordinary_control.f90` | Passes gfortran; Flang crashes; LFortran miscaptures the live ancestor host. The expected values and actual callback invocations are retained. |
| Ordinary expansion of same-name-specific integration | Passes gfortran and Flang, including type-bound/pointer/interface/actual and noninteroperable `C_FUNLOC` contexts. LFortran rejects the ordinary same-name explicit interface. |
| Ordinary singleton expansion of the C ABI case with native C helper | Compiles, links, and runs with gfortran, Flang, and LFortran. Both C calls enter the Fortran binding label and exercise `VALUE` and result ABI. |
| Ordinary fixture-oracle controls and deliberate mutants | Confirm complex-SIN identity/doubling and rank-two VALUE copy-back mutants fail; corrected character construction exercises system, ISO 10646, and opaque-kind fallback paths. |
| PDT/result/finalization/callback ordinary controls | Validated where supported; baseline compiler defects and unsupported PDT lowering are not converted into passing generic results. |
| Selected-image ERROR STOP calibration | Source and simulated-launcher mechanics check `TEST-STOP-IMAGE`, cache separation, unique reachability, normal-STOP/returned-stop rejection, and explicit inconclusive synchronization outcomes. No actual multi-image coarray runtime is installed, so propagation on two images remains unexecuted. |

No `GENERIC` fixture execution is validated locally. Accordingly, this matrix
records intended generic coverage, not local feature execution. A generic-
syntax rejection cannot satisfy an intended negative-rule row unless
prerequisite and diagnostic gating demonstrates that the compiler reached
that rule.

Remaining limits are explicit: draft readings and the intrinsic-signature
diagnostic classification need interpretation decisions; opaque character
kinds have only the disclosed portable payload subset; capability/image skips
are not execution evidence; and no finite fixture collection proves arbitrary
Fortran programs correct. Run schema 2 separates `profile_success` from
`coverage_complete`, and neither flag alone certifies full language
conformance.
