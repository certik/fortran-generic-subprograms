# Auto-generic subprograms (Fortran 2028)

This document states the rules for **generic subprograms** (also called auto-generic subprograms) as specified by the Fortran 2028 working draft **J3/26-007r1** (3 March 2026, WD 1539-1). It is a guide for implementers and for the conformance tests in `tests/`. Clause numbers below refer to that draft.

The normative text is the draft. This note paraphrases it, keeps the syntax, and adds examples. A few draft sentences are inconsistent; those are called out in [Wording issues](#wording-issues) and the tests follow the reading stated there.

Paper **J3/25-156r1** (John Reid, 26 June 2025) is the edit paper that introduced the feature. The draft has since changed the syntax. Where they differ, **26-007r1 wins**. The differences are listed in [Changes since 25-156r1](#changes-since-25-156r1).

## The three design questions

These answers are the feature author's guidance (not extra normative text). They match the draft's model of "one specific procedure per combination".

**Does a rank-generic dummy of ranks 0..7 generate every rank, and does a second generic dummy generate the full cross product? Or can a compiler wait and generate only the combinations a program uses?**

The meaning of the subprogram is the full set. There is one specific procedure for every combination of type and kind of each type-generic dummy and rank of each rank-generic dummy. Two generic dummies are independent: the set is the cross product, not the "diagonal".

A dummy whose type, kind, or rank is declared *from* another dummy (`TYPEOF`, `CLASSOF`, `KIND`, `RANK(RANK(...))`) is not itself generic, and it does not add a factor to the product.

The standard does not prescribe an object-file strategy. In theory a compiler could emit code only for combinations that are referenced. In practice a module procedure can be use-associated from a program that the compiler of the module cannot see, so implementations are expected to generate every specific when the module is compiled. An unused specific still has to be a legal procedure. The test `tests/invalid/mod_requires_same_kind.f90` is nonconforming even though nothing calls it.

**Is `SELECT GENERIC RANK` / `SELECT GENERIC TYPE` always compile time?**

Yes. Each specific procedure contains at most one block of each such construct. The block is chosen from the rank, or from the declared type and kind, of that specific. The other blocks are not part of that procedure, so they do not have to be valid for that specific's type or rank. The code that remains is ordinary straight-line Fortran. There is no runtime branch for the selection.

**How does this relate to templates, which are also in Fortran 2028?**

They overlap in some use cases, and they are complementary.

- A generic subprogram can mention only types and kinds that are known where it is written. The payoff is that one body spells a whole family of procedures.
- A template can be instantiated on types that do not exist yet, and one instantiation can declare new types and several procedures. Writing the template is more work.
- Neither feature replaces the other. A program can use both.

## What a generic subprogram is

A subprogram whose `FUNCTION` or `SUBROUTINE` statement has the prefix `GENERIC` is a **generic subprogram** (3.143.2, 15.6.2.4). It defines a **generic name** and a set of **unnamed** specific procedures with explicit interfaces. The name of the subprogram is the generic identifier for those specifics. There are no specific names.

The effect is the same as writing the body once per combination, deleting the `SELECT GENERIC` blocks that do not match that combination, giving each copy a distinct name, and declaring a generic identifier for those names — except that the specific names are not visible (15.6.2.4 NOTE 1).

A generic subprogram with **no** generic dummy argument is allowed. It defines a generic name with exactly one unnamed specific. The name is still generic, not specific, so it cannot be passed as an actual argument (15.6.2.4 NOTE 7).

```fortran
generic function square(x)
  real, intent(in), rank(0) :: x
  real :: square
  square = x**2
end function
```

`RANK(0)` is a single rank, so `x` is not rank-generic. `square` is still a generic name.

## Where the prefix may appear

`GENERIC` is a `prefix-spec` (R1530), alongside `PURE`, `SIMPLE`, `ELEMENTAL`, `IMPURE`, `RECURSIVE`, `NON_RECURSIVE`, `MODULE`, and a result type.

| Place | Allowed? |
| --- | --- |
| Module subprogram | Yes (C1582, C1564) |
| Internal subprogram of a **non-generic** host | Yes |
| Separate module procedure: interface body **and** the defining subprogram, both with `MODULE` and `GENERIC` | Yes (15.4.3.2 p4, C1564) |
| External subprogram | No |
| Interface body without `MODULE` | No |
| Abstract interface | No |
| Internal subprogram of a generic subprogram | No (C1583) |

`ENTRY` is not allowed in a generic subprogram (C1589). An asterisk (alternate-return) dummy is not allowed (C1584). A dummy procedure must have an explicit interface (C1585).

`RECURSIVE` is advisory, as elsewhere. `NON_RECURSIVE` is forbidden if any specific calls any specific of the same subprogram, including itself (15.6.2.1 p3). `PURE`, `SIMPLE`, and `ELEMENTAL` are allowed when **every** specific satisfies the rules of those prefixes.

## Generic dummy arguments

A **generic type declaration statement** is a type declaration that has a `generic-type-spec`, or a generic `RANK` clause, or both (8.2 p2). It is allowed only in the specification part of a generic subprogram (C801). It declares **exactly one** object, and that object must be a nonoptional dummy data object (C802).

```fortran
type(integer, real), intent(in) :: x          ! one generic dummy
type(integer, real), intent(in) :: y          ! a second, independent one
typeof(x), intent(in) :: z1, z2               ! not generic; two names are fine
```

`type(integer, real) :: x, y` is illegal: a generic type declaration has a single `entity-decl`.

A dummy declared with a `generic-type-spec` is **type-generic** (3.60.5). A dummy declared with a generic `RANK` clause is **rank-generic** (3.60.4). One dummy can be both. A dummy (or any other entity) that merely *takes* its type, kind, or rank from a generic dummy is not a generic dummy.

### Type specifiers that are generic

From 7.3.2.2:

```text
generic-type-spec        is TYPE ( generic-type-specifier-list )
                         or CLASS ( generic-type-specifier-list )
                         or generic-intrinsic-type-spec

generic-type-specifier   is intrinsic-type-spec
                         or derived-type-spec
                         or enum-type-spec
                         or enumeration-type-spec
                         or kind-generic-type-spec

kind-generic-type-spec   is generic-intrinsic-type-spec
                         or generic-derived-type-spec

generic-intrinsic-type-spec
                         is REAL    ( [ KIND = ] int-constant-expr )
                         or INTEGER ( [ KIND = ] int-constant-expr )
                         or LOGICAL ( [ KIND = ] int-constant-expr )
                         or COMPLEX ( [ KIND = ] int-constant-expr )
                         or CHARACTER ( gen-char-type-params )

gen-char-len             is *
                         or :

gen-char-type-params     is gen-char-len [ , [ KIND = ] int-constant-expr ]
                         or LEN = gen-char-len [ , KIND = int-constant-expr ]
                         or KIND = int-constant-expr , LEN = gen-char-len
```

The `int-constant-expr` in a `generic-intrinsic-type-spec` is a rank-one array (C718). Each element is a kind. `INTEGER(INTEGER_KINDS)`, `INTEGER(KIND=[INT32, INT64])`, and `INTEGER([INT32, INT64])` are the same idea. `ISO_FORTRAN_ENV` provides `INTEGER_KINDS`, `REAL_KINDS`, `LOGICAL_KINDS`, and `CHARACTER_KINDS` for "every kind the processor supports". There is no `REAL(*)` form; that alternative was rejected.

`CHARACTER` must state an assumed (`*`) or deferred (`:`) length. `CHARACTER(LEN=10, KIND=CHARACTER_KINDS)` is illegal (C717). So is a `*char-length` on the entity that is not `*` or `:` (C804). A `*char-length` is allowed only when every type in the spec is character (C803).

`CLASS(...)` may list only extensible types (C715). Intrinsic types, enum types, and enumeration types are not extensible, so they cannot appear in `CLASS(...)`.

A `generic-type-specifier-list` that contains **no** kind-generic specifier must contain **more than one** specifier (C716). Consequences:

| Written form | What it is |
| --- | --- |
| `integer` | Declaration type. Not generic. |
| `integer([int32, int64])` | Type-generic. One specifier, and it is kind-generic, so C716 does not require a second item. |
| `integer([int32])` | Type-generic, with a single combination. `SELECT GENERIC TYPE` is still allowed. |
| `type(integer)` | Ordinary `declaration-type-spec` (`TYPE(intrinsic-type-spec)`). The generic-list reading is forbidden by C716 because the only specifier is not kind-generic. Not a type-generic dummy. |
| `type(integer, real, complex)` | Type-generic. Default kind of each type. |
| `type(point)` | Ordinary derived type. Not type-generic. Combined with a generic `RANK` clause, the dummy is rank-generic only. |
| `class(point)` | Ordinary polymorphic dummy. Not type-generic. |
| `class(point, circle)` | Type-generic, provided both types are extensible and neither specific is TKR-compatible with the other (see [Distinguishability](#distinguishability)). |
| `type(t(k=[int32, int64], n=*))` | Type-generic parameterized type. The single specifier is kind-generic. |

Duplicate kind values in one kind array are kept as a single value (7.3.2.2 p2). Duplicate type/kind combinations in one `generic-type-spec` are likewise collapsed (p3). The dummy **stays generic** even if one combination remains. `TYPE(REAL(REAL64), DOUBLE PRECISION)` is one combination on a processor where those kinds are equal, and two combinations otherwise. Both spellings remain valid actual arguments.

### Parameterized derived types

```text
generic-derived-type-spec is type-name ( gen-tp-spec-list )
gen-tp-spec               is [ keyword = ] gen-tp-value
gen-tp-value              is int-constant-expr
                          or *
                          or :
```

The type must have at least one kind type parameter (C719). A length parameter's value must be `*` or `:`, and a kind parameter's value must be a scalar or a rank-one array (C722). At least one kind parameter must be a rank-one array (C723); a scalar kind is a fixed value, not a factor that can be omitted to dodge that rule. Keywords follow the usual "once you use a keyword, keep using them" rule (C720).

A specification in which every kind parameter is a scalar is an ordinary derived-type spec, not a generic one. An ordinary type-parameter value is scalar, so the generic form is the one that uses a rank-one array for at least one kind parameter. `TYPE(T(K=1, N=*))` is one ordinary parameterized type. `TYPE(T(K=[1, 2], N=*))` is generic.

Kind arrays multiply. The draft's example:

```fortran
type t(k1, k2, n)
  integer, kind :: k1, k2
  integer, len :: n
  real(k1) :: value(k2, n)
end type

type(t([kind(0.0), kind(0.0d0)], k2=[1, 2, 4, 8], n=*)), intent(inout) :: x
```

is eight specifics: two values of `k1` times four values of `k2`. `n` is assumed from the actual. On a processor where `kind(0.0)` and `kind(0.0d0)` are the same, p2 collapses `k1` and only four specifics remain.

### Generic rank

```text
rank-clause     is RANK ( rank-spec-list )
rank-spec       is scalar-int-constant-expr
                or rank-range-spec
rank-range-spec is scalar-int-constant-expr : scalar-int-constant-expr
```

A `RANK` clause is **generic** when it has a range or more than one `rank-spec` (8.5.17 p2). This is syntactic, and it is not revisited after duplicate removal:

| Clause | Generic? | Ranks |
| --- | --- | --- |
| `RANK(0)` | No | scalar |
| `RANK(2)` | No | 2 |
| `RANK(RANK(x))` | No | the rank of `x` in this specific |
| `RANK(0:0)` | Yes | only 0. `SELECT GENERIC RANK` is allowed. |
| `RANK(2, 2)` | Yes | only 2, after the duplicate is ignored |
| `RANK(0, 2, 4)` | Yes | 0, 2, 4 |
| `RANK(1:3, 7)` | Yes | 1, 2, 3, 7 |
| `RANK(0:MAX_RANK())` | Yes | every rank the processor supports for a non-coarray |
| `RANK(1:)` | Not a legal rank-spec | both ends of a range are required |
| `RANKOF(x)` | Not in the draft | write `RANK(RANK(x))` |

Each bound is a nonnegative integer constant expression, at most the processor's maximum rank for the corank of the entity (C875). `ISO_FORTRAN_ENV`'s `MAX_RANK([CORANK])` is that inquiry. Duplicate ranks in the list are ignored (8.5.17 p4).

A generic `RANK` clause gives the entity the `DIMENSION` attribute. The entity declaration itself must not also carry an `array-spec` (C876), so `rank(1:2) :: x(:)` is illegal. Rank 0 is scalar. A positive rank means:

- assumed-shape with every lower bound equal to **1**, if the dummy is not allocatable and not a pointer;
- deferred-shape, if it is allocatable or a pointer (the bounds then come from allocation or from the actual argument, as usual for deferred-shape dummies);
- never assumed-size, and never assumed-rank (`x(..)` is an `array-spec`).

`CONTIGUOUS` is only legal on array pointers, assumed-shape arrays, and assumed-rank objects. A generic rank set that includes 0 therefore cannot be `CONTIGUOUS`: the scalar specific would violate that rule. `RANK(1:3), CONTIGUOUS` is fine.

`ELEMENTAL` requires every dummy to be scalar. `ELEMENTAL` plus `RANK(0:0)` is legal (every specific is scalar, and the clause is still generic). `ELEMENTAL` plus `RANK(0:1)` is not, because the rank-1 specific is not scalar.

### What is not a generic dummy

These take a property from a generic dummy. They do not add combinations.

| Declaration | In a given specific |
| --- | --- |
| `typeof(x)` | Declared type and type parameters of `x`. A length parameter that is deferred on `x` stays deferred; an assumed length becomes that actual length, and the new entity is not assumed-length (7.3.2.1 p3 and NOTE 2). |
| `classof(x)` | Same declared type and type parameters, but polymorphic. |
| `real(kind(x))` | Real of the kind of `x`. Per specific, `x` has one kind, so `KIND(x)` is a constant expression there. |
| `rank(rank(x))` | The rank of `x`. Not a generic `RANK` clause. |
| `character(len=len(x)*2, kind=kind(x))` | A length that may depend on the execution value of `LEN(x)`, and a kind fixed for that specific. |

`TYPEOF` / `CLASSOF` of a whole generic dummy is the intended way to say "same type as that argument". The draft dropped the paper's extra constraints on what a kind selector may reference; under 15.6.2.4 p2 the body is checked **after** each generic dummy has been given a concrete type, kind, and rank, so `KIND(x)` and `RANK(x)` are ordinary inquiries in that specific.

A function result and a local variable are never generic dummies (they are not dummy data objects). A nonzero rank on a function result or local that is not allocatable and not a pointer is described by 8.5.17 p3 as assumed-shape, but an assumed-shape array has to be a dummy (8.5.8.3). The tests therefore give such results and locals the `ALLOCATABLE` attribute. See [Wording issues](#wording-issues).

## How the specifics are built

15.6.2.4 p1–p2:

1. Collect the type-generic dummies and the rank-generic dummies. A dummy that is both contributes its type/kind set **and** its rank set.
2. Expand each set, then delete duplicate values.
3. Form the Cartesian product. The number of specifics is the product of the sizes of those sets. Dummies that are not generic contribute a factor of 1.
4. For each tuple, reread the subprogram with every generic dummy fixed to that type, kind, and rank.
5. From each `SELECT GENERIC RANK` and `SELECT GENERIC TYPE`, delete every block that does not match this tuple.
6. What remains must be a standard-conforming procedure.

The draft's own counting example (15.6.2.4 NOTE 2), reduced to the declarations:

```fortran
generic subroutine subxy(x, y)
  type(integer([int32, int64]), real), rank(1:2), allocatable :: x
  type(integer([int32, int64]), real), rank(1:2), allocatable :: y
  typeof(x), rank(rank(y)), allocatable :: z
end subroutine
```

`x` has 3 type/kind combinations and 2 ranks. `y` has the same, independently. That is 6 × 6 = 36 specifics. `z` is not generic: its type follows `x` and its rank follows `y`.

```fortran
generic subroutine lift(x, y)
  type(integer([int32, int64]), real), rank(1:2), allocatable :: x
  typeof(x), rank(rank(x)), allocatable :: y, z
end subroutine
```

`y` is not generic. There are 6 specifics, and in each of them `x`, `y`, and `z` agree in type, kind, and rank.

A useful special case of the same rule is "same type, any rank of this argument":

```fortran
generic function copy(x) result(y)
  integer, intent(in), rank(0:2) :: x
  integer, allocatable, rank(rank(x)) :: y
  y = x
end function
```

Three specifics, not a type/rank matrix. `y = x` is legal for the scalar and for both array ranks, so no `SELECT` is required.

### The requirement that kills mismatched intrinsics

```fortran
generic real function bad(x, y)
  real([real32, real64]) :: x
  real([real32, real64]) :: y
  bad = mod(x, y)
end function
```

Four specifics are implied. `MOD` requires both arguments to have the same kind, so the two mixed-kind specifics are illegal, and the generic subprogram is illegal (15.6.2.4 NOTE 3). No call is required for the program to be nonconforming. The repair is to make the second argument dependent:

```fortran
generic function good(x, y) result(z)
  real([real32, real64]), intent(in) :: x
  typeof(x), intent(in) :: y
  typeof(x) :: z
  z = mod(x, y)
end function
```

Two specifics, and `MOD` is legal in both.

### Code generation

Normatively, the program contains every specific in the product. A compiler that is checking conformance has to reject the program if any of them is illegal, including ones that are never referenced.

A compiler that is generating code for a **module** procedure should emit all of them. Later program units can use-associate the generic and reference a combination this compilation cannot see. For an **internal** procedure the references are visible, and emitting only the used specifics is a possible optimization; the unused ones must still be checked for conformance if the implementation claims to diagnose that class of error. This test suite expects a diagnostic for a bad unused specific.

`SELECT GENERIC` does not change that set. It only chooses which statements appear inside each specific. It is not a device for requesting a subset of the product.

## `SELECT GENERIC RANK`

Syntax (11.1.10):

```text
[ name : ] SELECT GENERIC RANK ( selector )
   RANK ( rank-spec-list ) [ name ]
      block
   ...
   RANK DEFAULT [ name ]
      block
END SELECT [ name ]
```

The selector is the name of a **rank-generic dummy** (C1155). It is not a `TYPEOF` entity, not a `RANK(RANK(x))` entity, and not the function result. The paper's example that selects on the result is not legal in the draft; select on the rank-generic dummy.

`RANK(*)` belongs to `SELECT RANK` (assumed-rank). It is not a `rank-spec`.

Duplicate values in one guard's list are ignored. At most one `RANK DEFAULT` (C1156). A construct name on a guard or on `END SELECT` must match the `SELECT`. If `SELECT` has a name, `END SELECT` must repeat it; if it does not, `END SELECT` must not have one (C1157, C1158).

Execution model (11.1.10.2): a `RANK (list)` guard matches when the selector's rank is in the list. `RANK DEFAULT` matches when no list matched. Otherwise no block is selected, and that is legal. Branching to the `END SELECT` is allowed only from inside the construct.

This is **not** `SELECT RANK`:

| | `SELECT GENERIC RANK` | `SELECT RANK` |
| --- | --- | --- |
| Selector | Rank-generic dummy | Assumed-rank variable |
| When | Compile time, one block baked into each specific | Run time |
| Associate name | None. The dummy keeps its name. | Optional associate name |
| Rank 0 | The dummy is scalar in that specific | Associate is scalar |
| Bounds | Already fixed by 8.5.17 (assumed-shape lower bounds are 1) | Taken from the selector |
| `RANK(*)` | No | Yes, for assumed-size |

Because the unselected blocks are deleted, a block may use syntax that is illegal for other ranks:

```fortran
generic function pick(x) result(y)
  integer, intent(in), rank(0:2) :: x
  integer :: y
  select generic rank (x)
  rank (0)
    y = x
  rank (1)
    y = x(1)          ! illegal if x were scalar or rank 2
  rank (2)
    y = x(1, 1)
  end select
end function
```

Overlapping guards (`RANK(1:2)` and `RANK(2:3)` in one construct) are not given an explicit constraint, unlike `SELECT RANK`'s C1166. 11.1.10.2 still says each specific contains **at most one** block. A rank that matches two guards has no conforming interpretation. The tests treat that program as invalid.

A guard list that mentions a rank outside the dummy's set simply never matches. That is allowed, by the same rule that "no guard matched" is allowed.

## `SELECT GENERIC TYPE`

Syntax (11.1.11):

```text
[ name : ] SELECT GENERIC TYPE ( selector )
   DECLARED TYPE IS ( type-spec ) [ name ]
      block
   ...
   DECLARED TYPE DEFAULT [ name ]
      block
END SELECT [ name ]
```

The selector is a **type-generic** dummy (C1159). A dummy that is only rank-generic, including `CLASS(t), RANK(0:2)` where `CLASS(t)` is an ordinary polymorphic type, does not qualify.

The guard is `DECLARED TYPE IS`, not `TYPE IS`. The `type-spec` is an intrinsic type spec, derived type spec, enum type spec, or enumeration type spec (R702). It is not wrapped in `TYPE(...)`.

```fortran
declared type is (integer(int32))
declared type is (real)
declared type is (character(len=*))
declared type is (point)                 ! derived type
declared type is (t(k1=kind(0.0), k2=4, n=*))
declared type is (colour)                ! enum or enumeration type name
```

If the type has length parameters, every one of them must be assumed in the guard (C1160). `DECLARED TYPE IS (CHARACTER(LEN=10))` is illegal. Kind parameters are written out in full.

The same declared type and the same kind type parameter values must not appear in two guards (C1161). At most one default (C1162). Construct names work as for the rank construct (C1163).

The match uses the **declared type and kind type parameters** of the selector, never the dynamic type and never a length (11.1.11.2). There is no `CLASS IS` guard and no match of extensions. `DECLARED TYPE IS (REAL)` matches default real only. `DECLARED TYPE IS (INTEGER)` matches default integer only, not `INTEGER(INT64)`.

If the dummy was declared `CLASS(...)`, the specific is polymorphic, but the guard still sees the declared type that this specific was generated for. The dynamic type may be an extension of that declared type. Inspecting the dynamic type is what runtime `SELECT TYPE` is for, and it may appear **inside** the selected block:

```fortran
select generic type (x)
declared type is (base)
  select type (x)
  type is (base)
    k = 1
  class is (base)
    k = 3          ! dynamic type is an extension of base
  end select
end select
```

`TYPE IS` / `CLASS IS` here are the runtime construct. They are legal because, in this specific, `x` is an ordinary polymorphic dummy of declared type `base`.

As with rank, a block that is not selected for a given specific is deleted before conformance is checked. `CONJG` may appear in a complex block and not be valid for the real specific. A type/kind that matches no guard, and no default, contributes an empty selection. That is legal; it is not a way to delete the specific from the generic set.

C1161 is stricter than the rank rule: two guards must not name the same type and kind, even if a default could have disambiguated them. If `REAL(REAL64)` and `DOUBLE PRECISION` are the same kind on this processor, using both as guards violates C1161.

## Attributes, prefixes, and other statements

Anything that is legal for every specific (or legal inside the blocks that those specifics keep) is legal on the generic subprogram.

- `INTENT`, `VALUE`, `TARGET`, `ASYNCHRONOUS`, `VOLATILE`, `CONTIGUOUS` (when every rank is a legal contiguous entity), `ALLOCATABLE`, `POINTER`, and `CODIMENSION` are ordinary attributes of the dummy. The generic dummy itself cannot be `OPTIONAL` (C802). A **non-generic** dummy of the same subprogram can be `OPTIONAL`.
- `VALUE` copies the actual, including when the generic rank makes the dummy an array. The actual is unchanged if the procedure assigns to the dummy.
- Assumed-shape generic ranks have lower bound 1 in every dimension, regardless of the actual's lower bounds. Allocatable and pointer generic ranks are deferred-shape and keep the actual's bounds (8.5.8.4).
- A generic subprogram may call itself. The call is a generic reference and is resolved to one specific. `factorial(n-1)` resolves to the same type and kind. A call can also resolve to a **different** specific, for example an integer specific calling the real specific with `REAL(x)`.
- An internal procedure of a generic subprogram is cloned with each specific. It may use `TYPEOF` of a host generic dummy. It must not itself be generic.
- The subprogram may be `PURE` or `SIMPLE` when each specific is. `ELEMENTAL` is allowed when each specific meets 15.9.1 (scalar nonallocatable nonpointer noncoarray dummies, scalar result, intents present). An elemental specific is still elemental: an array actual is an elemental reference, not a generic-rank match. Generic rank and elemental rank are different mechanisms.
- Host association, use association, `BLOCK`, and specification expressions work as they do inside the specific you would have written by hand.

## Joining a generic set

If the subprogram name is already generic in the scoping unit, the new specifics are added to that set (15.6.2.4 NOTE 4). That existing set might come from an interface block, a `GENERIC` statement, or an earlier generic subprogram. Every pair of specifics must satisfy the usual distinguishability rules (15.4.3.4.5).

```fortran
interface set_to
  module procedure set_to_logical
end interface
! later, in the same module:
generic subroutine set_to(x)
  integer, intent(inout), rank(0) :: x
  ...
end subroutine
generic subroutine set_to(x)
  integer, intent(inout), rank(1:2) :: x
  ...
end subroutine
```

One generic name, several unnamed specifics, plus the named `set_to_logical`.

Two generic subprograms whose rank sets overlap (`RANK(0:2)` and `RANK(2:4)`) produce two specifics of rank 2 that are not distinguishable. The program is illegal even if the overlapping rank is never called.

### Operators, assignment, and generic names

A `PROCEDURE` statement or a `GENERIC` statement may name a generic procedure. That adds **all** of its specifics to the operator, the assignment, or the defined input/output (15.4.3.3 p3, 15.4.3.4.1 p2, R1507).

It must not add them to another **generic name**. C1505 and C1512 forbid a generic name whose specific is itself a generic name (no generic of generics). C1510 also forbids `MODULE PROCEDURE` of a generic name.

```fortran
interface operator(.myplus.)
  procedure myplus          ! every specific of generic myplus
end interface

interface wrapper
  procedure myplus          ! illegal: wrapper is a generic name
end interface
```

The usual operator and assignment constraints still apply to each specific: for an operator, one or two nonoptional data dummies with `INTENT(IN)` or `VALUE`, and a result that is not assumed-length character; for assignment, the first dummy `INTENT(OUT)` or `INTENT(INOUT)` and the second `INTENT(IN)` or `VALUE`.

The specific names do not need to be accessible at the `PROCEDURE` statement (15.4.3.2 NOTE 3). A private generic function can implement a public operator.

### Separate module procedures

```fortran
module m
  interface
    module generic function inc(n) result(r)
      use, intrinsic :: iso_fortran_env
      integer(integer_kinds), intent(in) :: n
      typeof(n) :: r
    end function
  end interface
end module

submodule (m) s
contains
  module generic function inc(n) result(r)
    use, intrinsic :: iso_fortran_env
    integer(integer_kinds), intent(in) :: n
    typeof(n) :: r
    r = n + 1
  end function
end submodule
```

Both the interface body and the defining subprogram carry `MODULE` and `GENERIC` (15.4.3.2 p4). The characteristics and dummy names match, as for any separate module procedure (C1561).

## Distinguishability

15.4.3.4.5 is unchanged, and it applies to the generated specifics.

Two data dummies are distinguishable when neither is TKR-compatible with the other (or one is allocatable and the other is a non-`INTENT(IN)` pointer, and the other cases in p6). Nonpolymorphic dummies are type-compatible only with the same declared type. Different intrinsic types, different kinds, and different ranks are therefore distinguishable.

Polymorphic dummies are not symmetric. `CLASS(base)` is type-compatible with `CLASS(extended)` when `extended` extends `base`, so those two specifics are **not** distinguishable. `CLASS(left, right)` is legal only when neither type is compatible with the other: typically two unrelated extensible types. `TYPE(base, extended)` is legal because `TYPE` is not polymorphic.

Elemental specifics are distinguished as if they were scalar. An array actual can still be an elemental reference, and if both an elemental and a nonelemental specific seem to match, the nonelemental one is chosen (C.10.6 p5). This suite does not rely on that tie-break.

## Worked examples

### Compile-time type selection

`CONJG` is only in the complex specific. A compiler that type-checked every block against every type would reject this. The draft requires it to be accepted.

```fortran
generic function mag(x) result(y)
  type(real, complex), intent(in) :: x
  real(kind(x)) :: y
  select generic type (x)
  declared type is (real)
    y = abs(x)
  declared type is (complex)
    y = abs(conjg(x))
  end select
end function
```

### The corrected form of the paper's rank example

The paper selected on the result and used an open rank range. The draft form is:

```fortran
generic function fun(x) result(y)
  type(type1), rank(0:7) :: x          ! type1 is not generic; the rank is
  typeof(x), allocatable, rank(rank(x)) :: y
  select generic rank (x)              ! x is the rank-generic dummy
  rank (0)
    ! scalar specific
  rank (1:3)
    ! ranks 1, 2, 3
  rank default
    ! ranks 4, 5, 6, 7
  end select
end function
```

Eight specifics, one per rank. `y` matches `x`.

### Recursive factorial

This is 15.6.2.4 NOTE 6, with the draft's spelling. Each specific recurses into itself because `n-1` has the same type and kind as `n`.

```fortran
generic recursive function factorial(n) result(res)
  use, intrinsic :: iso_fortran_env
  integer(integer_kinds) :: n
  typeof(n) :: res
  if (n > 1) then
    res = n * factorial(n - 1)
  else if (n < 0) then
    error stop "factorial is not defined for negative numbers"
  else
    res = 1
  end if
end function
```

### Elemental, by type rather than by rank

```fortran
elemental generic function add_one(x) result(y)
  type(integer, real), intent(in) :: x
  typeof(x) :: y
  y = x + 1
end function
```

Two scalar specifics. `add_one([1, 2, 3])` is an elemental reference to the integer specific, not a rank-generic one.

### Operator

```fortran
module m
  private
  public operator(.twice.)
  interface operator(.twice.)
    procedure dbl
  end interface
contains
  generic function dbl(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function
end module
```

The caller writes `2 .twice.` and does not need access to `dbl`.

## Constraint checklist

Checked by `tests/invalid/` unless noted.

| Rule | Statement |
| --- | --- |
| C801 | Generic type declaration only in a generic subprogram. |
| C802 | That declaration names one nonoptional dummy data object. Not a local, not a function result, not two names. |
| C715 | `CLASS` lists only extensible types. |
| C716 | A generic type list without a kind-generic specifier has at least two specifiers. |
| C717, C804 | Character length in a generic spec is assumed or deferred. |
| C718 | The kind expression is rank one. |
| C719, C722, C723 | A generic derived type has a kind parameter, length parameters are `*` or `:`, and at least one kind parameter is a rank-one array. |
| C875 | Rank bounds are in `0 .. max rank` for the entity's corank. |
| C876 | No `array-spec` on an entity with a generic `RANK` clause. |
| C1155 | `SELECT GENERIC RANK` selects a rank-generic dummy. |
| C1156 | At most one `RANK DEFAULT`. |
| C1157, C1158, C1163 | Construct names match. |
| C1159 | `SELECT GENERIC TYPE` selects a type-generic dummy. |
| C1160 | Length parameters in a type guard are assumed. |
| C1161 | A type and kind appear in at most one guard. |
| C1162 | At most one default type guard. |
| C1564, C1582 | `GENERIC` only on a module or internal subprogram, or together with `MODULE` on a separate module procedure interface. |
| C1583 | No generic internal of a generic. |
| C1584 | No asterisk dummy. |
| C1585 | Dummy procedures have an explicit interface. |
| C1589 | No `ENTRY`. |
| 15.4.3.4.5 | Specifics that share a generic identifier are distinguishable. `CLASS` of a type and of its extension is not. |
| 15.6.2.4 p2 | Every specific, after deletion of unselected blocks, conforms. `MOD` of independently generic kinds does not. |
| C1505, C1512 | A generic name is not a specific of another generic name. |
| C15135 | An elemental specific has scalar dummies. A generic rank that includes a positive rank cannot be elemental. |
| 11.1.10.2 | A rank that matches two guards does not conform (no explicit constraint number; see wording issues). |

## Changes since 25-156r1

The paper's straw votes that the draft kept: kind values are a rank-one array, not `*` (alternative 1a); a derived-type kind parameter may be scalar or rank one, and at least one is rank one (1.5b); duplicate kinds and duplicate type/kind pairs collapse (2a, 3a); duplicate ranks collapse and the dummy stays generic (5b); duplicate ranks inside one `SELECT GENERIC RANK` list are ignored (6b).

The draft then changed the feature further:

| Paper | Draft 26-007r1 |
| --- | --- |
| `TYPE IS` / `TYPE DEFAULT` | `DECLARED TYPE IS` / `DECLARED TYPE DEFAULT` |
| `RANKOF(x)` as a rank clause | `RANK(RANK(x))` |
| Open range `RANK(1:)` | Both bounds required: `RANK(1:MAX_RANK())` |
| `SELECT GENERIC RANK (y)` when `y` is `RANK(RANK(x))` | The selector is the rank-generic dummy |
| `TYPE(t1, t2) :: x, y` in examples | One name per generic type declaration (C802). The paper's own syntax already said a single `generic-dummy-arg-decl`; the draft's examples agree. |
| `RANK(*)` excluded from generic-rank guards by a constraint | `*` is simply not a `rank-spec` |
| Several constraints about not mentioning a generic dummy except as `KIND(x)` or `RANK(x)` | Removed. 15.6.2.4 p2 (check each specific after substitution) does that work. |

## Wording issues

These are defects or tensions in 26-007r1. The tests follow the reading in the right-hand column.

| Text | Reading used by the tests |
| --- | --- |
| C1162 says "TYPE DEFAULT", but R1157 and the examples say `DECLARED TYPE DEFAULT` / `DECLARED TYPE IS`. | The BNF is the syntax. `TYPE DEFAULT` and `TYPE IS` are rejected. |
| 8.5.17 p3 says a positive rank with no `ALLOCATABLE` or `POINTER` is assumed-shape, including for function results and locals. 8.5.8.3 defines assumed-shape as a dummy. NOTE 8 writes `REAL, RANK(RANK(a)) :: b` for a function result whose rank can be positive. | Nonallocatable nonpointer function results and locals in the tests are scalar, or their rank comes from a non-generic `RANK(0)`. Array results and locals that follow a generic rank are `ALLOCATABLE`. The NOTE 8 declaration is not used as a test. |
| `SELECT RANK` has C1166 (a rank value in at most one guard). `SELECT GENERIC RANK` does not, but 11.1.10.2 requires at most one block per specific. | Overlapping rank guards are invalid. |
| The paper required a generic rank list to specify at least one rank. The draft does not. `RANK(1:0)` names no rank. | Not tested. Avoid empty ranges. |
| C826 says rank + corank ≤ 15. The `MAX_RANK` examples also describe a processor whose maximum rank is 24. | No coarray tests. A generic rank plus a corank has to be legal for every rank in the set under whichever rule the processor implements. `MAX_RANK(corank)` is the portable upper bound. |
| C716 makes `TYPE(integer)` and `TYPE(point)` illegal as one-item generic lists, while R704 also parses them as ordinary type specs. | They are ordinary types, not type-generic. A one-item list is generic only when that item is kind-generic (`TYPE(INTEGER([INT32]))`, `TYPE(T(K=[1,2], N=*))`). |

## Tests

`tests/README.md` is the index. `tests/run.sh` compiles and runs `tests/valid`, expects `tests/runtime` to error-terminate, and expects `tests/invalid` to be rejected at compile time. Each valid program uses `error stop` for a failed check.
