# Auto-generic subprograms: specification and conformance tests

Fortran 2028 adds **generic subprograms**: one procedure body with a `GENERIC` prefix, expanded by the compiler into a set of unnamed specific procedures. The rules are in [doc/auto-generic-subprograms.md](doc/auto-generic-subprograms.md). That note follows the working draft **J3/26-007r1** (`26-007r1.pdf` in this directory). The earlier edit paper is J3/25-156r1; where the paper and the draft disagree, the draft is the one these tests implement.

## Layout

| Path | What it is |
| --- | --- |
| `doc/auto-generic-subprograms.md` | The rules, the cross product, compile-time `SELECT GENERIC`, and how this differs from templates |
| `tests/valid/` | Programs that must compile, run, and exit 0. A failed check is `error stop`. |
| `tests/runtime/` | A conforming program that must compile and then `error stop` |
| `tests/invalid/` | Programs that must be rejected at compile time |
| `tests/run.sh` | `FC=lfortran ./tests/run.sh` |

The feature is part of the draft standard. A compiler that has not implemented it yet will fail every file under `tests/valid` and `tests/runtime`, and will pass `tests/invalid` only because it rejects the new syntax.

## Readings the tests rely on

A few sentences in 26-007r1 do not line up. The specification says which reading the tests use. The important ones:

- Guards are spelled `DECLARED TYPE IS` and `DECLARED TYPE DEFAULT`.
- A generic declaration names one dummy. Dependent entities (`TYPEOF`, `RANK(RANK(x))`) are not generic and may share a statement.
- Array function results and locals whose rank follows a generic dummy are allocatable. The draft's assumed-shape wording does not cover a function result.
- A rank that matches two `SELECT GENERIC RANK` guards is rejected, because each specific may contain at most one block.
- Every specific in the cross product has to be legal, including specifics the program never calls.

## Valid tests

| File | What it checks |
| --- | --- |
| `intrinsic_types.f90` | `TYPE(INTEGER, REAL, COMPLEX)` and `TYPE(INTEGER, CHARACTER(LEN=*))`. `CONJG` and `LEN` appear only in the specific that can legally execute them. |
| `integer_kinds.f90` | `INTEGER(INTEGER_KINDS)` and `INTEGER(KIND=ks)` with a named rank-one array. |
| `real_complex_kinds.f90` | `REAL([REAL32, REAL64])` and `COMPLEX([REAL32, REAL64])`, including `KIND(x)` in `CMPLX`. |
| `logical_kinds.f90` | `LOGICAL(LOGICAL_KINDS)`. |
| `character_kinds.f90` | Assumed and deferred character length, a kind guard, and `KIND(s)` on the result. |
| `duplicate_type_kind.f90` | `TYPE(REAL(REAL64), DOUBLE PRECISION)` whether or not those kinds coincide. |
| `duplicates_remain_generic.f90` | A collapsed duplicate list is still generic, so `SELECT GENERIC` is legal. |
| `rank_bounds_and_result.f90` | Assumed-shape lower bounds are 1. Allocatable result. Subscripts only in the matching rank block. |
| `rank_allocatable_pointer.f90` | Allocatable bounds are the actual's bounds. Pointer assignment to a target whose rank follows the pointer. |
| `select_rank_default.f90` | `RANK DEFAULT` for ranks no list names. |
| `select_type_default.f90` | `DECLARED TYPE DEFAULT`, and a specific in which no block is selected. |
| `nested_select.f90` | One dummy that is both type-generic and rank-generic. |
| `cross_product.f90` | Two independent dummies, all 16 combinations. |
| `dependent_mod.f90` | `TYPEOF` second argument makes `MOD` legal. A non-generic array can follow the generic type. |
| `standard_note_shapes.f90` | The draft's 36-specific and 6-specific examples, as runnable procedures. |
| `parameterized_derived.f90` | Kind arrays multiply; an assumed length does not. A scalar kind parameter is not a factor. |
| `derived_and_class.f90` | `TYPE` of a parent and its extension. `CLASS` of unrelated types. Dynamic type is ignored by the generic guard and seen by `SELECT TYPE`. One-type `CLASS` plus a generic rank is rank-generic only. |
| `enumeration_types.f90` | Enumeration types in a generic type list. |
| `enum_bind_c.f90` | Interoperable enum types, using enum constructors. |
| `elemental.f90` | Elemental specifics, including `RANK(0:0)`, called with arrays. |
| `factorial.f90` | The draft's recursive example. Each specific calls itself. |
| `call_other_specific.f90` | The integer specific calls the real specific. |
| `full_rank_range.f90` | `RANK(0:MAX_RANK())`. |
| `no_generic_dummy.f90` | No generic dummy: one specific, and the name is still generic. |
| `construct_name.f90` | Construct names on both selects. |
| `prefixes.f90` | `PURE`, `SIMPLE`, `VALUE`, `CONTIGUOUS`, a non-generic `OPTIONAL` dummy, keywords. |
| `internal_host.f90` | Internal procedure of a generic, and a generic internal to an ordinary host. |
| `module_use.f90` | Use association, and a `BLOCK` local declared `TYPEOF`. |
| `separate_module_procedure.f90` | `MODULE GENERIC` on the interface and on the submodule procedure. |
| `extend_generic.f90` | A classic specific and several generic subprograms share one name. |
| `operator_and_assignment.f90` | Operator and defined assignment from a generic name. The unary operator's specific is private. |
| `dummy_procedure.f90` | Explicit-interface dummy procedure whose argument type follows the generic dummy. |

`tests/runtime/factorial_negative.f90` is the `n < 0` branch of the factorial example. It must compile and then error-terminate.

## Invalid tests

Each file names the constraint it violates. Several exist so that an implementation of the June 2025 paper, rather than the draft, fails: `type_is_syntax.f90`, `type_default_syntax.f90`, `rankof_syntax.f90`, `open_rank_range.f90`, and `star_all_kinds.f90`.

`mod_requires_same_kind.f90`, `contiguous_scalar_rank.f90`, and `elemental_nonscalar_rank.f90` are illegal because **some specific in the cross product** is illegal, even if the program never calls it. `overlapping_rank_guards.f90` is the "at most one block" case that has no separate constraint number.
