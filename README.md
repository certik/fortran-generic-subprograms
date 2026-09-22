# Auto-generic subprograms: specification and conformance tests

Fortran 2028 adds **generic subprograms**: one procedure body with a `GENERIC` prefix, expanded by the compiler into a set of unnamed specific procedures. The rules are in [doc/auto-generic-subprograms.md](doc/auto-generic-subprograms.md). That note follows the working draft **J3/26-007r1** (`26-007r1.pdf` in this directory). The earlier edit paper is J3/25-156r1; where the paper and the draft disagree, the draft is the one these tests implement.

## Layout

| Path | What it is |
| --- | --- |
| `doc/auto-generic-subprograms.md` | The rules, the cross product, compile-time `SELECT GENERIC`, and the readings where the draft disagrees with itself |
| `tests/valid/` | Programs that must compile, run, and exit 0. A failed check is `error stop`. A subdirectory is one multi-file test: sources are compiled separately in lexical order, then linked. |
| `tests/invalid_compile_time/` | Programs that must be rejected while compiling or linking |
| `tests/invalid_runtime/` | Programs that must compile and then terminate with a nonzero status below 128. These programs are conforming. The nonzero status is their own `error stop`. A signal death (status 128 or above) fails the test. |
| `tests/run.sh` | `FC=lfortran ./tests/run.sh` |

Coarray tests are standard Fortran. A compiler that needs an option to enable coarrays takes that option in `FCFLAGS`.

The feature is part of the draft standard. A compiler that has not implemented it yet will fail every file under `tests/valid` and `tests/invalid_runtime`, and will pass `tests/invalid_compile_time` only because it rejects the new syntax. The runner checks that a translation failed. It does not read the diagnostic text, so a rejection for an unrelated reason still counts.

Passing the suite means the compiler implements the rules this note and these programs cover. It does not, by itself, prove that some kind the source cannot name portably was executed. The specification says which kinds and ranks are called and why the others are still required to exist.

## Readings the tests rely on

A few sentences in 26-007r1 do not line up. The specification says which reading the tests use. The important ones:

- Guards are spelled `DECLARED TYPE IS` and `DECLARED TYPE DEFAULT`. `DECLARED TYPE IS (REAL)` and `DECLARED TYPE IS (INTEGER)` match the default kind only.
- A generic declaration names one dummy. Dependent entities (`TYPEOF`, `CLASSOF`, `RANK(RANK(x))`) are not generic and may share a statement. `CLASSOF` is polymorphic.
- `INTEGER(INT32)`, `CHARACTER(LEN=*)`, and `CHARACTER(*)` are ordinary declarations. A rank-one kind expression is what makes the intrinsic form generic.
- A `RANK` clause is allowed on a named constant, a dummy, or an allocatable or pointer (C877). Scalar results do not carry a `RANK` clause. Array results and locals whose rank follows a generic dummy are allocatable. NOTE 7 and NOTE 8 are not valid tests.
- A rank that matches two `SELECT GENERIC RANK` guards is rejected, because each specific may contain at most one block. `RANK(1:0)` is rejected. A guard rank the dummy never has is allowed, and that block is deleted before checking.
- Every specific in the cross product has to be legal, including specifics the program never calls. Each specific has its own `SAVE` locals.
- The subprogram name is a generic identifier. References, including a recursive call and a later `USE`, resolve as if the specifics were in a generic interface. The name is not a specific procedure, so it is not an actual argument, a procedure pointer, a type-bound procedure, or a `BIND(C)` label.
- Where an elemental specific and a nonelemental specific both match, the nonelemental one is chosen.
- The suite also rejects some violations that are "shall" requirements but not numbered constraints (`NON_RECURSIVE` calling another specific, overlapping rank guards, a branch into `END SELECT`, an empty rank range, `BIND(C)`). Fortran 4.2 does not require a diagnostic for every one of those. This suite does.

## Valid tests

| File | What it checks |
| --- | --- |
| `intrinsic_types.f90` | `TYPE(INTEGER, REAL, COMPLEX)` and `TYPE(INTEGER, CHARACTER(LEN=*))`. `CONJG` and `LEN` appear only in the specific that can legally execute them. |
| `integer_kinds.f90` | `INTEGER(INTEGER_KINDS)` and `INTEGER(KIND=ks)`. Calls default integer, `INT32`, `INT64`, and `SELECTED_INT_KIND` ranges 2, 4, 9, and 18. |
| `real_complex_kinds.f90` | `REAL(REAL_KINDS)` and `COMPLEX([REAL32, REAL64])`, including `KIND(x)` in `CMPLX`. |
| `logical_kinds.f90` | `LOGICAL(LOGICAL_KINDS)`, including `LOGICAL_KINDS(1)`. |
| `character_kinds.f90` | Assumed and deferred character length, a kind guard, `TYPEOF` of assumed and deferred length, and ASCII kind. |
| `ordinary_scalar_kind.f90` | `CHARACTER(LEN=*)` and `INTEGER(INT32)` are ordinary dummies beside a type-generic one. |
| `duplicate_type_kind.f90` | `TYPE(REAL(REAL64), DOUBLE PRECISION)` whether or not those kinds coincide. |
| `duplicates_remain_generic.f90` | A collapsed duplicate list is still generic, so `SELECT GENERIC` is legal. |
| `rank_bounds_and_result.f90` | Assumed-shape lower bounds are 1. Allocatable result. Subscripts only in the matching rank block. |
| `rank_allocatable_pointer.f90` | Allocatable and pointer dummies keep the actual's bounds. Pointer assignment to a target whose rank follows the pointer. |
| `select_rank_default.f90` | `RANK DEFAULT` for ranks no list names. |
| `select_rank_gaps.f90` | No guard and no default leaves the selection empty. A guard outside the rank set is deleted, so its block may be illegal for every real rank. |
| `select_type_default.f90` | `DECLARED TYPE DEFAULT`, and a specific in which no block is selected. |
| `declared_type_default_kind.f90` | `DECLARED TYPE IS (REAL)` and `DECLARED TYPE IS (INTEGER)` match the default kind only. |
| `nested_select.f90` | One dummy that is both type-generic and rank-generic. |
| `cross_product.f90` | Two independent dummies, all 16 combinations. |
| `dependent_mod.f90` | `TYPEOF` second argument makes `MOD` legal. A non-generic array can follow the generic type. |
| `standard_note_shapes.f90` | The draft's 36-specific and 6-specific examples, as runnable procedures. |
| `parameterized_derived.f90` | Kind arrays multiply; an assumed length does not. |
| `pdt_scalar_kind.f90` | A scalar kind parameter is not a factor. |
| `pdt_deferred_length.f90` | Deferred length `n=:`, with `n=*` in the type guard. |
| `derived_and_class.f90` | `TYPE` of a parent and its extension. `CLASS` of unrelated types. Dynamic type is ignored by the generic guard and seen by `SELECT TYPE`. One-type `CLASS` plus a generic rank is rank-generic only. |
| `classof_dependent.f90` | `CLASSOF` is polymorphic, follows the generic dummy, and does not add a combination. |
| `enumeration_types.f90` | Enumeration types in a generic type list. |
| `enum_bind_c.f90` | Interoperable enum types, using enum constructors. |
| `elemental.f90` | Elemental specifics, including `RANK(0:0)`, called with arrays. |
| `elemental_tie_break.f90` | A nonelemental specific wins over an elemental one when both match. |
| `factorial.f90` | The draft's recursive example. Each specific calls itself. |
| `call_other_specific.f90` | The integer specific calls the real specific. |
| `full_rank_range.f90` | `RANK(0:MAX_RANK())`, executed for ranks 0 through 15. |
| `coarray_rank.f90` | `RANK(0:MAX_RANK(1))` on a coarray dummy, including rank 14. |
| `no_generic_dummy.f90` | No generic dummy: one specific, and the name is still generic. The result has no `RANK` clause. |
| `construct_name.f90` | Construct names on both selects. |
| `branch_to_end_select.f90` | A branch to `END SELECT` from inside the construct. |
| `prefixes.f90` | `PURE`, `SIMPLE`, `VALUE`, `CONTIGUOUS` (including a noncontiguous actual), a non-generic `OPTIONAL` dummy, keywords. |
| `save_per_specific.f90` | A `SAVE` local belongs to one specific. |
| `internal_host.f90` | Internal procedure of a generic, and a generic internal to an ordinary host. |
| `module_use.f90` | Use association, and a `BLOCK` local declared `TYPEOF`. |
| `separate_module_procedure.f90` | `MODULE GENERIC` on the interface and on the submodule procedure. |
| `submodule_procedure.f90` | `GENERIC` on an ordinary module procedure in a submodule. |
| `separate_compilation/` | The module is compiled before the program that uses two of its specifics. |
| `extend_generic.f90` | A classic specific and several generic subprograms share one name. |
| `extend_intrinsic.f90` | A generic named `SIN` overrides integer and real, and leaves complex `SIN` to the intrinsic. |
| `operator_and_assignment.f90` | Operator and defined assignment from a generic name. The unary operator's specific is private. The call is `.twice. 4`. |
| `defined_io.f90` | `WRITE(FORMATTED)` receives every specific of a generic subroutine. |
| `dummy_procedure.f90` | Explicit-interface dummy procedure whose argument type follows the generic dummy. |

`tests/invalid_runtime/factorial_negative.f90` is the `n < 0` branch of the factorial example. It is a conforming program. It must compile and then error-terminate without being killed by a signal.

## Compile-time tests

Each file names the rule it violates. Several exist so that an implementation of the June 2025 paper, rather than the draft, fails: `type_is_syntax.f90`, `type_default_syntax.f90`, `rankof_syntax.f90`, `open_rank_range.f90`, and `star_all_kinds.f90`.

`mod_requires_same_kind.f90`, `contiguous_scalar_rank.f90`, and `elemental_nonscalar_rank.f90` are illegal because **some specific in the cross product** is illegal, even if the program never calls it. `overlapping_rank_guards.f90`, `non_recursive_calls_specific.f90`, `empty_rank_range.f90`, `branch_into_select.f90`, and the `bind_c_*.f90` files are the requirements that have no separate constraint number.

Other files added for the gaps in the first draft of this suite: scalar kind and assumed-length character are not selectors; `CLASSOF` is not a selector; C804's explicit `*char-length`; rank above `MAX_RANK()` and above `MAX_RANK(1)`; a reference that matches no specific; `MODULE PROCEDURE` and a `GENERIC` statement naming a generic; type-bound procedure and procedure pointer; elemental allocatable dummy, missing intent, and allocatable result; construct names on `END SELECT` and on a guard; parameterized-type keyword order, missing parameter, duplicate parameter, scalar kind that is not generic, `n=:` in a guard, and duplicate guards; a separate module procedure that drops `GENERIC` or `MODULE`, or that expands to a different set.
