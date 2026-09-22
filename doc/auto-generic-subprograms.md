# Auto-generic subprograms (Fortran 2028)

This document states the rules for **generic subprograms** (also called auto-generic subprograms) as specified by the Fortran 2028 working draft **J3/26-007r1** (3 March 2026, WD 1539-1). It is a guide for implementers and for the conformance tests in `tests/`. Clause numbers below refer to that draft.

The normative text is the draft. This note paraphrases it, keeps the syntax, and adds examples. Several draft sentences are inconsistent. They are called out in [Unresolved draft interpretations](#unresolved-draft-interpretations), and their tests are quarantined rather than used to declare either accepting or rejecting processors nonconforming.

Paper **J3/25-156r1** (John Reid, 26 June 2025) is the edit paper that introduced the feature. The draft has since changed the syntax. Where they differ, **26-007r1 wins**. The differences are listed in [Changes since 25-156r1](#changes-since-25-156r1).

## Status of a rule

This guide uses three deliberately different statuses:

1. **Settled syntax and constraints.** Numbered syntax rules, numbered constraints, and the other detect-and-report classes in 4.2 require a processor to be capable of reporting a violation. Clause 4.2 does not say that every reported violation has to make translation exit unsuccessfully.
2. **Unnumbered requirements.** A program that violates an unnumbered “shall” is nonconforming, but 4.2 does not generally require a diagnostic for it. The suite can request these as **enhanced diagnostics** without presenting them as the default diagnostic obligation.
3. **Unresolved draft interpretations.** Internally inconsistent or incomplete wording is exercised only under an explicit draft-reading profile. Acceptance and rejection are both conformance-neutral until the wording is resolved.

The coverage status of individual requirements and fixtures is in [conformance-coverage.md](conformance-coverage.md).

## The three design questions

These answers are the feature author's guidance (not extra normative text). They match the draft's model of "one specific procedure per combination".

**Does a rank-generic dummy of ranks 0..7 generate every rank, and does a second generic dummy generate the full cross product? Or can a compiler wait and generate only the combinations a program uses?**

The meaning of the subprogram is the full semantic set. There is one specific procedure for every combination of the deduplicated type/kind set of each type-generic dummy and the deduplicated rank set of each rank-generic dummy. Distinct generic factors form a Cartesian product, not a “diagonal”.

Genericity is classified **property by property**, not once for the whole dummy. A dependent property does not add its own factor, but it does not cancel another property that is declared generically. For example, in 8.2 NOTE 1, `X` has two kinds and three ranks, while `Y` has an independent two-kind generic type declaration and a rank that follows `X`:

```fortran
real([real32, real64]), rank(1:3), intent(in)    :: x
real([real32, real64]), rank(rank(x)), intent(inout) :: y
```

`X` contributes a two-kind factor and a three-rank factor; `Y` contributes another two-kind factor but no rank factor. The result is **2 × 3 × 2 = 12 specifics**. Conversely, `TYPEOF(x), RANK(0:2) :: y` has a dependent type but remains rank-generic and contributes three ranks. `TYPEOF`, `CLASSOF`, `KIND`, `RANK(RANK(...))`, specification expressions, and fixed declarations are dependencies only for the properties they determine.

The standard does not prescribe an object-file strategy, separate machine-code bodies, or physical dispatch. An implementation may clone code, share one body with hidden specialization information, instantiate lazily, or use another strategy. It must nevertheless expose the same per-specific interfaces and procedure identities, preserve per-specific `SAVE` state and internal-procedure identity, and make every specific that can later be referenced available. An unused specific must still be semantically conforming. The test `tests/invalid_compile_time/mod_requires_same_kind.f90` exercises that residual requirement, and `tests/valid/separate_compilation/` prevents whole-program visibility from being assumed.

**Is `SELECT GENERIC RANK` / `SELECT GENERIC TYPE` always compile time?**

Semantically, yes. Each specific procedure contains at most one block of each such construct. The block is chosen from the rank, or from the declared type and kind, of that specific, and the other blocks are absent when the residual procedure is checked. This is a static language interpretation, not a physical code-generation mandate: an implementation may share code or contain an internal runtime dispatch as long as the observable behavior, interfaces, pruning exemptions, and per-specific state are exactly those of the statically selected specifics.

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

The result above is a scalar declared without a `RANK` clause. C877 allows a `RANK` clause only on a named constant, a dummy data object, or an allocatable or pointer. An array result whose rank follows a generic dummy is therefore legal when it is `ALLOCATABLE` or `POINTER`, for example `TYPEOF(x), ALLOCATABLE, RANK(RANK(x)) :: result`. NOTE 7 writes `TYPEOF(x), RANK(RANK(x)) :: square` and NOTE 8 writes `REAL, RANK(RANK(a)) :: b` for plain function results; those forms violate C877. See [Ranked results, locals, and named constants](#ranked-results-locals-and-named-constants).

## Resolving a reference

15.6.2.4 makes the subprogram name the generic identifier of the generated specifics. A reference is resolved with the usual generic rules (15.5.5.2, 15.4.3.4.5), as if those specifics had been listed in a generic interface block and then had their names hidden. Inside the subprogram, a reference to the function name (when `RESULT` is used) or a recursive subroutine call is a generic reference. `factorial(n-1)` selects the specific whose type and kind match `n-1`. One specific may call a different specific of the same name.

15.5.5.1 was not edited to list generic subprograms among the ways a name is established to be generic, and 15.5.5.2 still says "the specific procedure in the interface block." 15.2.2.2 still says a subprogram defines one procedure. Those sentences lose to 15.6.2.4: the name is generic, the specifics are unnamed, and no specific name is visible.

A generic subprogram whose name is already the generic name of an intrinsic can extend that intrinsic. A reference that matches one of its specifics calls that specific. A reference that matches none of them can fall back to the intrinsic (15.5.5.2 p5), but only while the intrinsic remains accessible. Under 15.4.3.4.5 p8, if the user generic’s procedures and the intrinsic are not **all functions** or **all subroutines**, the intrinsic is not accessible by that generic name. An explicit `INTRINSIC` declaration has the corresponding all-functions-or-all-subroutines constraint C855.

Semantically, each specific is a separate procedure. It has its own instances, its own saved local variables, and its own internal procedures. A `SAVE` local is not shared across kinds or ranks. An implementation may keep one physical body and a hidden specialization key, but then saved state and internal-procedure identities must also be partitioned by specific; merely sharing one `SAVE` object would be wrong.

## Where the prefix may appear

`GENERIC` is a `prefix-spec` (R1530), alongside `PURE`, `SIMPLE`, `ELEMENTAL`, `IMPURE`, `RECURSIVE`, `NON_RECURSIVE`, `MODULE`, and a result type.

| Place | Allowed? |
| --- | --- |
| Module subprogram | Yes (C1582, C1564) |
| Internal subprogram of a **non-generic** host | Yes |
| Separate module procedure: interface body **and** the defining subprogram, both with `MODULE` and `GENERIC` | The prefix syntax is explicitly allowed (15.4.3.2 p4, C1564), but a generic dummy declaration in the interface body exposes the C801 tension described below. |
| External subprogram | No |
| Interface body without `MODULE` | No |
| Abstract interface | No |
| Internal subprogram of a generic subprogram | No (C1583) |

`ENTRY` is not allowed in a generic subprogram (C1589). An asterisk (alternate-return) dummy is not allowed (C1584). A dummy procedure must have an explicit interface (C1585).

The ordinary prefix constraints still apply: a prefix specification is not repeated (C1555), `IMPURE` is not combined with `PURE` or `SIMPLE` (C1556), and `NON_RECURSIVE` is not combined with `RECURSIVE` (C1557). `RECURSIVE` is advisory, as elsewhere. `NON_RECURSIVE` is forbidden if any specific directly or indirectly calls any specific of the same subprogram, including itself (15.6.2.1 p3). `PURE`, `SIMPLE`, and `ELEMENTAL` are allowed only when every residual specific satisfies their requirements; an operation in a pruned generic-selection block is absent, but the same operation in a retained block still counts.

The draft explicitly describes a `MODULE GENERIC` interface body and says that it declares a generic separate module procedure (15.4.3.2 p4). C801, however, permits a generic type declaration statement only in the specification part of a **generic subprogram**, and an interface body is not a subprogram. A singleton `MODULE GENERIC` interface with no generic dummy avoids that declaration conflict; a genuinely expanding interface does not. The suite quarantines this as `generic-interface-declarations` rather than choosing a normative winner.

## Generic dummy arguments

A **generic type declaration statement** is a type declaration that has a `generic-type-spec`, or a generic `RANK` clause, or both (8.2 p2). It is allowed only in the specification part of a generic subprogram (C801). It declares **exactly one** object, and that object must be a nonoptional dummy data object (C802).

```fortran
type(integer, real), intent(in) :: x          ! one generic dummy
type(integer, real), intent(in) :: y          ! a second, independent one
typeof(x), intent(in) :: z1, z2               ! not generic; two names are fine
```

`type(integer, real) :: x, y` is illegal: a generic type declaration has a single `entity-decl`.

A dummy declared with a `generic-type-spec` is **type-generic** (3.60.5). A dummy declared with a generic `RANK` clause is **rank-generic** (3.60.4). One dummy can be both. These classifications are independent:

| Declaration | Type property | Rank property | Factors contributed |
| --- | --- | --- | --- |
| `TYPE(INTEGER,REAL), RANK(0:2) :: x` | generic | generic | 2 type/kind × 3 rank |
| `TYPEOF(x), RANK(0:2) :: y` | dependent on `x` | generic | 3 rank |
| `REAL([REAL32,REAL64]), RANK(RANK(x)) :: y` | generic | dependent on `x` | 2 kind |
| `TYPEOF(x), RANK(RANK(x)) :: y` | dependent on `x` | dependent on `x` | none |

Thus it is inaccurate to call a whole dummy nongeneric merely because one of its properties is dependent. A property adds a factor exactly when its declaration uses the corresponding generic syntax.

C802 limits the entity list of the **generic type declaration statement**. Other attributes can still be supplied by ordinary separate specification statements, and those attributes combine in every specific. For example, a type-generic dummy can receive `INTENT`, `ALLOCATABLE`, `POINTER`, `VALUE`, or a fixed `DIMENSION` in a separate statement where the ordinary rules permit it. A separate fixed- or assumed-rank `DIMENSION` declaration does not become a generic `RANK` clause.

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

The `int-constant-expr` in a `generic-intrinsic-type-spec` is a rank-one array (C718). Each element is a kind. `INTEGER(INTEGER_KINDS)`, `INTEGER(KIND=[INT32, INT64])`, and `INTEGER([INT32, INT64])` are the same idea. `ISO_FORTRAN_ENV` provides `INTEGER_KINDS`, `REAL_KINDS`, `LOGICAL_KINDS`, and `CHARACTER_KINDS` for every kind the processor supports. There is no `REAL(*)` form; that alternative was rejected.

Named storage-size constants are not portable promises of availability. `INT32`, `INT64`, `REAL32`, and `REAL64` have negative values when the corresponding representation method is unavailable (17.10.2.16, 17.10.2.31). `SELECTED_CHAR_KIND("ASCII")` returns `-1` when ASCII is unavailable (17.9.197). A supported kind value may be **zero**: the standard does not require positive kind values, and tests must distinguish “negative means unavailable” from “zero means unavailable”. Consequently:

- a fixture that directly mentions one of these optional kinds declares a processor capability requirement;
- a runtime `IF (INT32 >= 0)` cannot protect `INTEGER(INT32) :: x`, `1_INT32`, or another unsupported-kind declaration or literal, because the whole program unit must be valid during translation; and
- inventory arrays are the portable way to request all kinds, while generated callers can exercise each reported value.

`CHARACTER` must state an assumed (`*`) or deferred (`:`) length. `CHARACTER(LEN=10, KIND=CHARACTER_KINDS)` is illegal (C717). So is a `*char-length` on the entity that is not `*` or `:` (C804). A `*char-length` is allowed only when every type in the spec is character (C803).

`CHARACTER(LEN=*)` and `CHARACTER(*)` **without a kind expression** match both the ordinary character grammar and the generic intrinsic grammar. Unlike `INTEGER(INT32)`, there is no scalar kind expression for C718 to reject in the generic parse. The draft does not select one parse. Under `character-ordinary-parse` the dummy is assumed-length and not type-generic; under `character-generic-parse` it is a singleton default-character generic and may be selected by `SELECT GENERIC TYPE`. These are mutually exclusive draft readings, not a settled preference.

The paired fixtures use `DECLARED TYPE DEFAULT`, not a `CHARACTER(LEN=*)` type guard, so this parse question is observed independently of the separate C736/C7124/C1160 assumed-length-guard tension.

`CHARACTER(LEN=*, KIND=1)` has an ordinary valid parse, while its generic parse violates C718 because the kind expression is scalar. A rank-one kind expression such as `CHARACTER(LEN=*, KIND=CHARACTER_KINDS)` is unambiguously generic because an ordinary kind selector is scalar. Likewise, `INTEGER(INT32)` is ordinary, whereas `INTEGER([INT32])` is generic.

`CLASS(...)` may list only extensible types (C715). Intrinsic types, enum types, and enumeration types are not extensible, so they cannot appear in `CLASS(...)`.

A `generic-type-specifier-list` that contains **no** kind-generic specifier must contain **more than one** specifier (C716). Consequences:

| Written form | What it is |
| --- | --- |
| `integer` | Declaration type. Not generic. |
| `integer(int32)` | Ordinary scalar kind selector. Not type-generic. `SELECT GENERIC TYPE` is illegal. |
| `integer([int32, int64])` | Type-generic. One specifier, and it is kind-generic, so C716 does not require a second item. |
| `integer([int32])` | Type-generic, with a single combination. `SELECT GENERIC TYPE` is still allowed. |
| `type(integer)` | Ordinary `declaration-type-spec` (`TYPE(intrinsic-type-spec)`). The generic-list reading is forbidden by C716 because the only specifier is not kind-generic. Not a type-generic dummy. |
| `type(integer, real, complex)` | Type-generic. Default kind of each type. |
| `type(point)` | Ordinary derived type. Not type-generic. Combined with a generic `RANK` clause, the dummy is rank-generic only. |
| `class(point)` | Ordinary polymorphic dummy. Not type-generic. |
| `class(point, circle)` | Type-generic, provided both types are extensible and neither specific is TKR-compatible with the other (see [Distinguishability](#distinguishability)). |
| `type(t(k=[int32, int64], n=*))` | Type-generic parameterized type. The single specifier is kind-generic. |
| `type(t(k=1, n=*))` | Ordinary parameterized type. Every kind parameter is scalar, so this is not a `generic-derived-type-spec`. |
| `character(len=*)` | Ambiguous between ordinary assumed length (`character-ordinary-parse`) and a singleton generic parse (`character-generic-parse`). |
| `character(len=*, kind=1)` | Ordinary. The generic parse violates C718 because the kind is scalar. |
| `character(len=*, kind=character_kinds)` | Type-generic. The kind expression is rank one, so only the generic production matches. |
| `character(*)` | Same pair of unresolved ordinary/generic readings as `character(len=*)`. |

Duplicate kind values in one kind array are kept as a single semantic value (7.3.2.2 p2). Duplicate type/kind combinations in one `generic-type-spec` are likewise collapsed (p3), even when they were written differently. The dummy **stays generic** even if one combination remains. `TYPE(REAL(REAL64), DOUBLE PRECISION)` is one combination on a processor where those kinds are equal, and two combinations otherwise.

Deduplication is per set, before the Cartesian product. Equal sets on `x` and `y` are still two independent factors. The draft does not, however, say what survives when two character or PDT specifiers have the same type and kind but different assumed/deferred length modes, for example assumed `*` versus deferred `:`. That is the quarantined `mixed-length-dedup` reading.

### Parameterized derived types

```text
generic-derived-type-spec is type-name ( gen-tp-spec-list )
gen-tp-spec               is [ keyword = ] gen-tp-value
gen-tp-value              is int-constant-expr
                          or *
                          or :
```

The type must have at least one kind type parameter (C719). A length parameter's value must be `*` or `:`, and a kind parameter's value must be a scalar or a rank-one array (C722). At least one kind parameter must be a rank-one array (C723); a scalar kind is a fixed value, not a factor. Each type parameter appears at most once, and a parameter with no default has to appear (C721). A parameter that has a default can be omitted; its default then supplies one fixed value, provided the complete generic spec still satisfies C717 and C723. Keywords follow the usual “once you use a keyword, keep using them” rule (C720).

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

Length parameters never add a generic-resolution factor (7.2 p2). `n=*` is assumed from the effective argument in each specific; `n=:` remains deferred where the entity and context permit it. Kind parameters, including defaulted ones, are compile-time values. Distinct assumed/deferred length modes can still affect characteristics even though they do not distinguish generic references, which is why deduplicating otherwise equal mixed-length entries is unresolved.

A PDT kind parameter is a user-defined integer parameter, not necessarily an intrinsic representation-method selector. Its legal values can include zero or negative integers unless the type definition uses that value in a context, such as `INTEGER(k)`, that independently requires a supported intrinsic kind. Inherited kind parameters participate in a generic PDT spec in the same way as directly declared parameters.

### `TYPE`, `CLASS`, defaults, and extensibility

`TYPE(...)` generates nonpolymorphic specifics. An actual of an extension type does not match a nonpolymorphic dummy declared as its parent. `TYPE(abstract_type)` is not a valid residual declaration (C707), but concrete `SEQUENCE` and `BIND(C)` types can appear in a `TYPE` list. `CLASS(...)` generates polymorphic specifics; C715 therefore permits only extensible declared types in its list. Abstract types can be extensible and can appear with `CLASS`, but `BIND(C)` and `SEQUENCE` derived types are not extensible and cannot. These properties are determined from the type definition, including one that appears later in the module, not from textual hints at the generic declaration.

`CLASS(*)` and `TYPE(*)` are ordinary unlimited-polymorphic and assumed-type declaration forms, not generic type lists. Either can be combined with a generic `RANK` clause where its own rules permit, making the dummy rank-generic only. The resulting selector uses are still limited by the pre-existing name-use constraints: in particular, C725 does not permit an assumed-type `TYPE(*)` variable name as a `SELECT GENERIC RANK` selector, even if its `RANK` clause is generic.

A `TYPE(...)` generic list can also mix intrinsic types, derived types, enum types, and enumeration types. Interoperable enumerators are integer named constants, whereas enum and enumeration constructors produce values of their nonintrinsic types. Those distinctions remain after expansion. None of these nonextensible type categories can appear in `CLASS(...)`.

The dynamic type of a `CLASS` actual can be an extension, but generic selection and `SELECT GENERIC TYPE` use the **declared** type and kind of the specific, not the dynamic type. A runtime `SELECT TYPE` can inspect the dynamic type inside the retained block.

For parameterized derived types, kind values participate in generic resolution and length values do not. Defaulted kind parameters may be omitted from an ordinary derived-type spec under C7121 and 7.5.9 p3; the omitted value is the declared default. This also matters in a `DECLARED TYPE IS` guard under the intended guard reading: kinds may use defaults, but every length parameter must be written as assumed (`*`) because C1160 says each length parameter is assumed. The legality of writing that `*` in a generic guard is itself the `assumed-length-guards` wording tension described below.

Default intrinsic kinds are scoped properties, not universal numeric constants. A bare `REAL`, `INTEGER`, `LOGICAL`, or `CHARACTER` in a generic list or guard denotes the default kind in that scoping unit. `DEFAULT KIND` and a `USE ... DEFAULT_KINDS` clause can change those defaults (8.7), and an interface body starts with the standard defaults unless its own scope changes or imports them as specified by 8.7. Separate-interface matching and guard expectations must compare the resulting kind values, not merely identical source spellings.

R504 fixes the statement order in a specification part: `USE` statements, then `IMPORT` statements, then `DEFAULT KIND` statements, then the implicit part. In particular, `DEFAULT KIND` precedes `IMPLICIT NONE`:

```fortran
use, intrinsic :: iso_fortran_env, only: int64
default kind (integer=int64)
implicit none
```

The new words do not become reserved tokens. Fortran remains case-insensitive and context-sensitive: identifiers such as `generic`, `rank`, `type`, `select`, `declared`, and `default` remain usable where an identifier is expected, and ordinary continuation rules apply inside the new statements. A parser must distinguish the generic productions from ordinary declarations by grammar and constraints, not by globally reserving those spellings.

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
| `RANK(0:MAX_RANK())` | Yes | every rank reported by `MAX_RANK()` under C875; values above 15 expose the C826 conflict |
| `RANK(2:2)` | Yes | only 2. A range is generic even when the two ends are equal. |
| `RANK(1:0)` | Generic syntax, empty set | 8.5.17 p4 makes the range empty, but the draft has no explicit nonempty-set requirement |
| `RANK(1:)` | Not a legal rank-spec | both ends of a range are required |
| `RANKOF(x)` | Not in the draft | write `RANK(RANK(x))` |

Each bound is a nonnegative integer constant expression at most the processor's maximum rank for the entity's corank (C875). `ISO_FORTRAN_ENV`'s `MAX_RANK([CORANK])` is that inquiry, so `RANK(0:MAX_RANK()+1)` violates C875. Duplicate ranks in the list are ignored (8.5.17 p4).

C826 independently says rank plus corank does not exceed 15, while 17.10.2.24 explicitly illustrates `MAX_RANK()==24`. For coranks within the written portable limit, the default interpretation therefore uses an upper bound no greater than both values, conceptually `MIN(15-corank, MAX_RANK(corank))`; literal `0:15` for noncoarrays and `0:14` for corank one express the minimum portable profile without adopting an extended-rank reading. Exercising a processor-advertised rank above 15 is opt-in under `extended-rank-limit`. A compiler is not called nonconforming for either side of that unresolved conflict.

`MAX_RANK(corank)` itself is not a universal “corank 16 is unsupported” test. It returns a supported nonnegative maximum rank when that corank is available, and exactly `-HUGE(0_STANDARD_INTEGER)` only when it is unsupported. Thus a query for corank 16 may validly return a nonnegative result on an extended processor; the portable C826 profile and the processor inquiry result are recorded separately.

The conflict does **not** mean a processor-dependent high-rank declaration is syntactically impossible. A single `RANK(MAX_RANK())` is an ordinary, nongeneric `RANK` clause and can declare an `ALLOCATABLE`, `POINTER`, or named constant under C877. On a processor whose `MAX_RANK()` exceeds 15, that otherwise available declaration exposes the same C826 tension.

A range whose first bound is greater than its second, such as `RANK(1:0)`, names no rank. Likewise, a rank-one kind expression can be zero-sized. Neither 7.3.2.2, 8.5.17, nor 15.6.2.4 explicitly requires a nonempty factor or a nonempty final set. Whether such a declaration denotes zero specifics or is invalid is quarantined as `empty-expansion`.

A generic `RANK` clause gives the entity the `DIMENSION` attribute. The entity declaration itself must not also carry an `array-spec` (C876), so `rank(1:2) :: x(:)` is illegal. Rank 0 is scalar. A positive rank means:

- assumed-shape with every lower bound equal to **1**, if the dummy is not allocatable and not a pointer;
- deferred-shape, if it is allocatable or a pointer (the bounds then come from allocation or from the actual argument, as usual for deferred-shape dummies);
- never assumed-size, and never assumed-rank (`x(..)` is an `array-spec`).

The `DIMENSION` attribute is still specified only once. A separate `DIMENSION` statement cannot be layered on an entity that already acquired `DIMENSION` from its `RANK` clause (C819), even though other nonconflicting attributes may be stated separately.

A type-generic declaration that has **no generic `RANK` clause** may use the ordinary array forms: explicit shape, assumed shape, assumed size, or assumed rank. Those ranks are characteristics of each type specific, not additional specialization factors. C876 forbids the `array-spec` only when the declaration also has a generic `RANK` clause.

An assumed-rank dummy and a rank-generic dummy are different mechanisms:

```fortran
type(integer, real), intent(in) :: a(..)       ! type-generic, assumed-rank
type(integer, real), intent(in), rank(0:2) :: b ! type-generic and rank-generic
```

`a` contributes only its type/kind factor. Each generated type specific still accepts any supported actual rank and needs runtime `SELECT RANK` when rank-specific operations are required. Under the literal C845 list, the assumed-rank name may be a selector of runtime `SELECT RANK` or, where the other `SELECT TYPE` constraints are met, runtime `SELECT TYPE`, but **not** `SELECT GENERIC TYPE`; C845 was not extended to name the new construct. Type-generic assumed-rank code therefore uses permitted inquiry functions such as `RANK`, runtime rank selection where needed, or a common body that is valid for every generated type rather than selecting the assumed-rank dummy directly with `SELECT GENERIC TYPE`.

`b` contributes both type/kind and rank factors; its rank is fixed in each specific and `SELECT GENERIC RANK` is a static semantic selection. An ordinary fixed `RANK(0)`, `RANK(2)`, or `RANK(RANK(x))` similarly does not make a dummy rank-generic.

`CONTIGUOUS` is only legal on array pointers, assumed-shape arrays, and assumed-rank objects. A generic rank set that includes 0 therefore cannot be `CONTIGUOUS`: the scalar specific would violate that rule. `RANK(1:3), CONTIGUOUS` is fine.

`ELEMENTAL` requires every dummy to be scalar. `ELEMENTAL` plus `RANK(0:0)` is legal (every specific is scalar, and the clause is still generic). `ELEMENTAL` plus `RANK(0:1)` is not, because the rank-1 specific is not scalar.

### Dependent and nongeneric properties

These forms take one property from a generic dummy. They do not add a factor for that property, although the same dummy can still be generic in another property.

| Declaration | In a given specific |
| --- | --- |
| `typeof(x)` | Declared type and type parameters of `x`. A length parameter that is deferred on `x` stays deferred; an assumed length becomes that actual length, and the new entity is not assumed-length (7.3.2.1 p3 and NOTE 2). |
| `classof(x)` | Same declared type and type parameters, but polymorphic. |
| `real(kind(x))` | Real of the kind of `x`. Per specific, `x` has one kind, so `KIND(x)` is a constant expression there. |
| `rank(rank(x))` | The rank of `x`. Not a generic `RANK` clause. |
| `character(len=len(x)*2, kind=kind(x))` | A length that may depend on the execution value of `LEN(x)`, and a kind fixed for that specific. |

`TYPEOF` / `CLASSOF` of a whole generic dummy is the intended way to say “same declared type and parameters as that argument”. The draft dropped the paper's extra constraints on what a kind selector may reference; under 15.6.2.4 p2 the body is checked **after** every generic factor has a concrete value, so `KIND(x)`, `RANK(x)`, bounds, and specification expressions are interpreted in that specific.

### Ranked results, locals, and named constants

A function result and a local variable are never generic dummies because they are not dummy data objects. They can nevertheless have characteristics that depend on a generic dummy.

C877 permits any `RANK` clause—including `RANK(0)` and `RANK(RANK(x))`—only on a named constant, a dummy data object, or an entity with `ALLOCATABLE` or `POINTER`. Therefore:

```fortran
typeof(x), allocatable, rank(rank(x)) :: copy  ! legal result/local
typeof(x), pointer,     rank(rank(x)) :: view  ! legal result/local
typeof(x),              rank(rank(x)) :: bad   ! violates C877
```

A scalar result normally has no `RANK` clause. A positive-rank plain entity would be described as assumed-shape by 8.5.17 p3, but assumed-shape arrays are dummies (8.5.8.3), which is why C877 excludes plain locals and results. NOTE 7 and NOTE 8 use the excluded form.

A named constant is the other legal C877 case. With positive rank, a `RANK` clause declares an implied-shape named constant whose lower bounds are all one (8.5.17 p3 and 8.5.8.6). A single `RANK(MAX_RANK())` on a named constant remains nongeneric even though the rank expression is processor dependent.

An allocatable **result** is a result characteristic, but a function reference with an allocatable result is not thereby an allocatable variable. Under 9.2, only a function reference with a data-pointer result can be a variable. `ALLOCATED(f())` is therefore invalid even when `f` has an allocatable result, because `ALLOCATED` requires an allocatable variable (17.9.13).

## How the specifics are built

15.6.2.4 p1–p2:

1. Identify each generic **property**. Every generic type spec contributes one semantic type/kind set; every generic `RANK` clause contributes one rank set. A dummy that is both contributes both factors. A dummy with a dependent type and generic rank, or generic type and dependent rank, contributes only the generic property.
2. Expand each factor and remove duplicate semantic values within that factor. A PDT's independent kind arrays form the type/kind set before this outer product.
3. Form the Cartesian product of all remaining factors. Fixed and dependent properties do not add factors. Equal sets on different dummies remain independent.
4. For each tuple, interpret dependent types, kinds, ranks, lengths, bounds, dummy procedure interfaces, and result characteristics using the selected values.
5. Delete every unselected block of every `SELECT GENERIC RANK` and `SELECT GENERIC TYPE` construct.
6. Check all remaining statements and characteristics as an ordinary specific procedure.

The draft gives no explicit rule for a factor that becomes empty; that case is quarantined rather than folded into this settled algorithm.

The property-wise point is visible in 8.2 NOTE 1:

```fortran
generic subroutine partial(x, y)
  use, intrinsic :: iso_fortran_env
  real([real32, real64]), rank(1:3), intent(in) :: x
  real([real32, real64]), rank(rank(x)), intent(inout) :: y
end subroutine
```

There are two independent kind choices (`x` and `y`) and three rank choices (`x`); `y`'s rank follows `x`. This is 12 specifics, not six and not 36.

The draft's own counting example (15.6.2.4 NOTE 2), reduced to the declarations:

```fortran
generic subroutine subxy(x, y)
  type(integer([int32, int64]), real), rank(1:2), allocatable :: x
  type(integer([int32, int64]), real), rank(1:2), allocatable :: y
  typeof(x), rank(rank(y)), allocatable :: z
end subroutine
```

`x` has 3 type/kind combinations and 2 ranks. `y` has the same, independently. That is 6 × 6 = 36 specifics. `z` contributes no factor: its type follows `x` and its rank follows `y`.

```fortran
generic subroutine lift(x, y)
  type(integer([int32, int64]), real), rank(1:2), allocatable :: x
  typeof(x), rank(rank(x)), allocatable :: y, z
end subroutine
```

`y` contributes no factor in this example. There are 6 specifics, and in each of them `x`, `y`, and `z` agree in type, kind, and rank. If `y` instead had `TYPEOF(x), RANK(0:2)`, its type would still follow `x` but its generic rank would multiply the set by three.

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

Only `SELECT GENERIC` has the deletion rule in 15.6.2.4 p2. A runtime `IF`, even one whose condition becomes a constant after specialization, does not remove its other branch from the Fortran program before semantic checking:

```fortran
if (kind(x) == real32) then
  ! This branch still has to be valid in every residual specific.
end if
```

The same applies to declarations in nested `BLOCK` constructs and to unsupported-kind literals. Constant folding may remove machine code, but it cannot retroactively make an invalid declaration or procedure reference conforming. Use `SELECT GENERIC TYPE` or `SELECT GENERIC RANK` when a statement is valid only for selected specifics.

### Code generation

Normatively, the semantic generic set contains every specific in the product, and 15.6.2.4 p2 requires the residual statements to conform for every one, including specifics that are never referenced. That “shall” is not a numbered constraint, so the default 4.2 diagnostic obligation and an optional enhanced rejection policy are reported separately by the suite.

Nothing requires one emitted machine-code body per semantic specific, eager emission, or runtime dispatch. A module file and object strategy may preserve enough information to instantiate a later use-associated combination. An internal procedure may be optimized with complete knowledge of its callers. In all cases, unavailable combinations cannot be silently omitted from semantic checking, and shared implementation code must preserve the observable per-specific interfaces, saved state, and internal-procedure identities.

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

The selector is the name of a **rank-generic dummy** (C1155). The syntax has no associate name, and a section or component is not permitted. It is not a `TYPEOF` entity, not a `RANK(RANK(x))` entity, and not the function result. C1155 also does not override other restrictions on using that name: C725 prevents an assumed-type `TYPE(*)` dummy from being used as this selector. The paper's example that selects on the result is not legal in the draft; select on an otherwise permitted rank-generic dummy.

`RANK(*)` belongs to `SELECT RANK` (assumed-rank). It is not a `rank-spec`.

Each `RANK(...)` guard contains the same `rank-spec-list` syntax as a `RANK` clause, so it can mix individual values and closed ranges. Duplicate values in one guard's list are ignored. At most one `RANK DEFAULT` is allowed (C1156). Default is a fallback when no list matches; its textual position does not give it priority over a matching list.

The repeated guard grammar allows an empty construct with no guards at all. Such a construct retains no block in any specific. A construct name on a guard or on `END SELECT` must match the `SELECT`; if `SELECT` has a name, `END SELECT` must repeat it, and if it does not, `END SELECT` must not have one (C1157, C1158). A named `EXIT construct-name` inside a retained block can complete the named selection construct under 11.1.14. A branch to `END SELECT` is permitted only from within the construct.

Execution model (11.1.10.2): a `RANK (list)` guard matches when the selector's rank is in the list. `RANK DEFAULT` matches when no list matched. Otherwise no block is selected, and that is legal. Branching to the `END SELECT` is allowed only from inside the construct.

This is **not** `SELECT RANK`:

| | `SELECT GENERIC RANK` | `SELECT RANK` |
| --- | --- | --- |
| Selector | Rank-generic dummy | Assumed-rank variable |
| When | Static semantics: each specific retains at most one block | Run time |
| Associate name | None. The dummy keeps its name. | Optional associate name |
| Rank 0 | The dummy is scalar in that specific | Associate is scalar |
| Bounds | Already fixed by 8.5.17 (assumed-shape lower bounds are 1) | Taken from the selector |
| `RANK(*)` | No | Yes, for assumed-size |

Because the unselected blocks are deleted **before the residual specific is checked**, a block may contain statements that would be illegal for other ranks:

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

Overlapping guards (`RANK(1:2)` and `RANK(2:3)` in one construct) are not given an explicit constraint, unlike `SELECT RANK`'s C1166. 11.1.10.2 still says each specific contains **at most one** block. A rank that matches two guards therefore violates an unnumbered requirement. It belongs to the enhanced-diagnostics profile; 4.2 does not turn it into a mandatory-rejection case.

A guard list that mentions a rank outside the dummy's set simply never matches. That is allowed, by the same rule that “no guard matched” is allowed. The unmatched block is deleted from every specific before conformance is checked, so it may contain code that would be illegal for every rank the dummy actually has. `tests/valid/select_rank_gaps.f90` covers both. An ordinary `IF` around the same code would not provide this exemption.

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

The selector is a **type-generic dummy argument** (C1159). The syntax has no associate-name form. A component, expression, section, `TYPEOF`/`CLASSOF` entity, or function result is not the selector merely because its type depends on a type-generic dummy. A dummy that is only rank-generic, including `CLASS(t), RANK(0:2)` where `CLASS(t)` is an ordinary polymorphic type, does not qualify.

The selector must also be a permitted use of its name. C845 allows an assumed-rank variable name as the selector of runtime `SELECT RANK` or runtime `SELECT TYPE`; it does not mention `SELECT GENERIC TYPE`. On the literal draft wording, a type-generic assumed-rank dummy therefore cannot be selected directly by this construct.

The guard is `DECLARED TYPE IS`, not `TYPE IS`. The `type-spec` is an intrinsic type spec, derived type spec, enum type spec, or enumeration type spec (R702). It is not wrapped in `TYPE(...)`.

```fortran
declared type is (integer(int32))
declared type is (real)
declared type is (character(len=*))
declared type is (point)                 ! derived type
declared type is (t(k1=kind(0.0), k2=4, n=*))
declared type is (colour)                ! enum or enumeration type name
```

Under C1160, if the type has length parameters, the guard must specify every one as assumed (`*`); neither an explicit length nor deferred `:` satisfies that wording. `DECLARED TYPE IS (CHARACTER(LEN=10))` is therefore a settled C1160 violation under the intended guard syntax. For a PDT, a kind parameter that has a default may be omitted under C7121 and 7.5.9 p3, so guard kinds need not all be written explicitly; omitted kinds take their defaults. A length parameter may not be omitted merely because it has a default, because C1160 specifically requires every length parameter to be assumed.

There is a separate syntax-context tension: C736 and C7124 do not clearly permit `*` in a **generic** type guard even though C1160 requires it. Fixtures that need an assumed-length generic guard are therefore quarantined as `assumed-length-guards`; the intended reading is that generic guards are an omitted context in those general restrictions.

The same declared type and the same kind type parameter values must not appear in two guards (C1161). At most one default is allowed (C1162). Default is chosen only when no `DECLARED TYPE IS` guard matches, regardless of textual order. The grammar also permits an empty construct with no guards. Construct names, named `EXIT`, and branches to the end work as for the rank construct (C1163, 11.1.11.2, 11.1.14).

The match uses the **declared type and kind type parameters** of the selector, never the dynamic type and never a length (11.1.11.2). There is no `CLASS IS` guard and no generic match of extensions. `DECLARED TYPE IS (REAL)` matches the default real kind in that scoping unit only; `DECLARED TYPE IS (INTEGER)` similarly matches the scoped default integer kind, not every integer kind. `DEFAULT KIND` and `USE ... DEFAULT_KINDS` therefore affect bare intrinsic guards (8.7). `tests/valid/declared_type_default_kind.f90` distinguishes a default kind from another kind.

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

As with rank, a block that is not selected for a given specific is deleted before conformance is checked. `CONJG` may appear in a complex block and need not be valid for the real specific. A type/kind that matches no guard, with no default, retains no block. That is legal and does not delete the specific from the generic set. A runtime `IF` does not have this pruning rule.

C1161 is stricter than the rank rule: two guards must not name the same type and kind, even if a default could have disambiguated them. If `REAL(REAL64)` and `DOUBLE PRECISION` are the same kind on this processor, using both as guards violates C1161.

## Attributes, prefixes, and other statements

Anything that is legal for every specific (or legal inside the blocks that those specifics keep) is legal on the generic subprogram.

- `INTENT`, `VALUE`, `TARGET`, `ASYNCHRONOUS`, `VOLATILE`, `CONTIGUOUS` (when every rank is a legal contiguous entity), `ALLOCATABLE`, `POINTER`, and `CODIMENSION` are ordinary attributes of the dummy. The generic dummy itself cannot be `OPTIONAL` (C802). A **non-generic** dummy of the same subprogram can be `OPTIONAL`.
- Attributes can be split between the generic declaration and ordinary separate attribute statements. C802's single-entity rule applies to the generic type declaration statement, not to unrelated `INTENT`, `VALUE`, `ALLOCATABLE`, `POINTER`, or other allowed statements.
- `VALUE` copies the actual, including when the generic rank makes the dummy an array. The actual is unchanged if the procedure assigns to the dummy.
- Assumed-shape generic ranks have lower bound 1 in every dimension, regardless of the actual's lower bounds. Allocatable and pointer generic ranks are deferred-shape and keep the actual's bounds (8.5.8.4).
- A type-generic assumed-rank dummy (`TYPE(... ) :: x(..)`) remains assumed-rank in each type specific; it is not expanded by actual rank. A fixed `RANK(n)` or dependent `RANK(RANK(x))` likewise does not add a rank factor.
- After generic resolution selects a specific, all ordinary argument-association rules apply. An allocatable dummy requires an allocatable actual where 15.5.2.6 requires one; a pointer dummy requires the corresponding pointer/target properties under 15.5.2.7; an `INTENT(OUT)` or `INTENT(INOUT)` actual must be definable; and type, kind, rank, optional presence, and keywords must agree with that selected interface. Generic expansion does not weaken those checks.
- A generic subprogram may call itself. The call is a generic reference and is resolved to one specific. `factorial(n-1)` resolves to the same type and kind. A call can also resolve to a **different** specific, for example an integer specific calling the real specific with `REAL(x)`.
- A dummy procedure must have an explicit interface (C1585). After the surrounding generic factors are fixed, the dummy procedure's argument and result characteristics must form a valid explicit interface for that specific. An implicit-interface `EXTERNAL` dummy is not enough, and the generic name itself cannot be used as a `PROCEDURE(interface-name)` because it is not a specific interface name.
- A function result is not a generic dummy, but its declared type, kind, length, rank, allocatable/pointer status, and dependent bounds are characteristics of each generated function (15.3.3). `TYPEOF`, `KIND`, and a C877-permitted allocatable or pointer `RANK` clause can make those characteristics follow a generic dummy.
- Allocation, deallocation, finalization, polymorphic dynamic type, and `INTENT(OUT)` entry effects are the ordinary effects of the selected specific. For example, finalization of an `INTENT(OUT)` actual occurs for the generated declared type, and allocating a polymorphic rank-generic dummy with `SOURCE=` establishes the normal dynamic type and shape.
- An internal procedure of a generic subprogram belongs to the generated specific whose host it uses. It may use `TYPEOF` or another property of a host generic dummy, but it must not itself be generic (C1583). An implementation that shares code still has to preserve distinct semantic internal-procedure identities.
- The subprogram may be `PURE` or `SIMPLE` when each specific is. `ELEMENTAL` is allowed when each specific meets 15.9.1 (scalar nonallocatable nonpointer noncoarray dummies, scalar result, intents present). An elemental specific is still elemental: an array actual is an elemental reference, not a generic-rank match. Generic rank and elemental rank are different mechanisms.
- Host association, use association, `BLOCK`, and specification expressions work as they do inside the specific you would have written by hand.
- A saved local is per specific. Calling the integer specific does not advance a `SAVE` counter in the real specific, even if both specifics share one physical implementation body.

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

The same procedure is not inserted twice under one accessible generic identifier. C1511 prohibits repeating it through a generic interface block, and C1513 does the same for a `GENERIC` statement. This is different from adding a distinct but indistinguishable generated specific, which violates the pairwise distinguishability constraints.

### Association, renaming, and accessibility

The generic subprogram name participates in the ordinary generic-identifier model:

- A public module generic is accessible by `USE`; `ONLY` can select it, and a rename gives it a different local generic identifier (14.2.2 p2, p6, p8).
- Multiple use paths may associate one local identifier with multiple ultimate entities when those entities are generic interfaces (14.2.2 p9). Their combined specifics must satisfy 15.4.3.4.5.
- Host association establishes a generic name only when the nested scope has no declaration of that name (15.5.5.1 p2(5)). A local generic can use the same identifier as an accessible generic and extend that set under 15.4.3.4.1 p5 and 15.6.2.4 NOTE 4.
- Accessibility controls whether the generic identifier is imported or exposed; it does not remove inaccessible specifics from pairwise distinguishability checks (15.4.3.4.5 p1).
- Renaming changes the local identifier used in resolution, not the identities or characteristics of the specifics. Resolution considers local and use-associated interfaces, then eligible host-associated interfaces, then an accessible intrinsic fallback (15.5.5.2).

The draft's 15.5.5.1 list was not updated to say directly that a generic-subprogram definition establishes its name as generic. That editorial omission is overridden by the explicit statement in 15.6.2.4 p1 that the subprogram name is the generic identifier for its unnamed specifics.

### Association with a derived-type constructor

A generic name may be the same as a derived-type name, provided all procedures in the generic interface are functions (15.4.3.4.1 p6). This is the standard custom-constructor pattern, including for a type with private components. At an occurrence such as `T(args)`, C7132 is a disambiguation rule: if `args` is a valid actual-argument list that resolves to the same-named generic function, the occurrence is that function reference, not a structure constructor. Otherwise, if the component syntax is valid, it can be the ordinary structure constructor.

Generated functions from a generic subprogram can join such a constructor-associated generic just like named functions. They must remain distinguishable from the other procedures in the generic interface; the structure constructor itself is not an additional procedure against which pairwise procedure distinguishability is checked. Defining an overlapping custom-constructor generic is legal, and no negative test is warranted merely because a resolvable function call also has constructor-like token syntax.

### Operators, assignment, and generic names

A `PROCEDURE` statement or a `GENERIC` statement may name a generic procedure. That adds **all** of its specifics to an operator, assignment, or defined input/output generic (15.4.3.3 p3, 15.4.3.4.1 p2-p3, R1507). All six non-name forms are valid generic specifications:

```fortran
generic :: operator(.myop.)     => function_family
generic :: assignment(=)        => assignment_family
generic :: read(formatted)      => formatted_read_family
generic :: read(unformatted)    => unformatted_read_family
generic :: write(formatted)     => formatted_write_family
generic :: write(unformatted)   => unformatted_write_family
```

The operator target must expand entirely to eligible functions, the assignment target entirely to eligible two-argument subroutines, and each defined-I/O target entirely to subroutines with the corresponding 12.6.4.8.2 interface. A generic family cannot contribute only the convenient subset of its specifics.

It must not add them to another **generic name**. C1505 and C1512 forbid a generic name whose specific is itself a generic name (no generic of generics). C1510 also forbids `MODULE PROCEDURE` of a generic name.

```fortran
interface operator(.myplus.)
  procedure myplus          ! every specific of generic myplus
end interface

interface wrapper
  procedure myplus          ! illegal: wrapper is a generic name
end interface
```

A **generic separate-module interface body** is different from that prohibited `PROCEDURE myplus` statement. Under 15.4.3.4.1 p2, the body itself specifies all specifics of the generic separate module procedure and contributes them directly to its enclosing generic interface:

```fortran
interface operator(.myop.)
  module generic function myop_interface(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
  end function
end interface
```

This contribution rule applies whether the enclosing specification is a named generic, operator, assignment, or defined I/O. It does not rely on naming the generic in a `PROCEDURE` statement. Writing the generic dummy declarations needed by such a body nevertheless exposes the separate C801 `generic-interface-declarations` tension; that syntax question is quarantined without discarding the contribution rule itself.

The usual operator and assignment requirements still apply to **every** generated specific:

- an operator has one or two nonoptional data dummies with `INTENT(IN)` or `VALUE`, a result that is not assumed-length character, and—when extending an intrinsic operator—dummy TKR that differs from the intrinsic operation;
- defined assignment is a two-dummy subroutine, with the first dummy `INTENT(OUT)` or `INTENT(INOUT)` and the second `INTENT(IN)` or `VALUE`, and it satisfies the rank/type conditions that distinguish it from intrinsic assignment; and
- the generated specifics remain pairwise distinguishable under C1514 or C1515.

For defined I/O, formatted read/write each have six dummies and unformatted read/write each have four, with the exact types, ranks, and intents in 12.6.4.8.2. In particular, the `dtv` dummy is scalar and is `INTENT(INOUT)` for reads and `INTENT(IN)` for writes; an extensible `dtv` uses `CLASS`, and every length parameter is assumed. A generic family is eligible only if every contributed specific has the appropriate interface and the `dtv` dummies are distinguishable under C1516.

The specific names do not need to be accessible at the `PROCEDURE` statement (15.4.3.2 NOTE 3). A private generic function can implement a public operator.

### Separate module procedures

The following is the intended shape under the `generic-interface-declarations` reading:

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

Both the interface body and the defining subprogram carry `MODULE` and `GENERIC` (15.4.3.2 p4). C1561 requires the **same characteristics and dummy argument names** as the corresponding interface body. Characteristics are semantic properties listed in 15.3, not textual declarations. Equivalent kind expressions, reordered duplicate values that denote the same set, or a different but equivalent declaration spelling need not be character-for-character identical. Conversely, identical-looking bare intrinsic declarations can differ if their scoped default kinds differ.

For a generic separate module procedure, the intended comparison is between the expanded semantic sets: corresponding unnamed specifics have the same dummy and result characteristics, dependency relationships, attributes, and dummy names. Merely counting the same number of specifics is insufficient. `NON_RECURSIVE` also appears on both sides or neither (C1563), and a binding label, when one is valid, matches under C1562. Dropping `GENERIC` or `MODULE` on the defining subprogram does not define that generic separate module procedure.

`GENERIC` without `MODULE` is otherwise allowed on a module procedure that is not a separate module procedure, including one written directly in a submodule. The unresolved point is narrower: C801 literally excludes the generic dummy declarations from the interface body even though 15.4.3.2 p4 describes the body.

A `GENERIC` subprogram may also be an ordinary module procedure of a submodule. It is then visible to the other module procedures of that submodule. It is use-associated from outside only when a separate-module interface in the ancestor module publishes it.

## What the generic name is not

The specifics have no names. The generic name cannot be used where a specific procedure is required.

- It is not an actual argument (C1537) and not a procedure-pointer target (10.2.2.4). That includes a generic subprogram with no generic dummy, whose single specific is still unnamed (15.6.2.4 NOTE 7).
- It is not an `interface-name` for a procedure declaration such as `PROCEDURE(generic_name)`, because that context requires an abstract interface or a specific procedure with an explicit interface. Nor can it be supplied to `C_FUNLOC`, which requires an interoperable specific procedure rather than a generic set.
- It is not a type-bound procedure (C798). A type-bound `GENERIC` statement names specific bindings of that type, not a generic subprogram.
- `MODULE PROCEDURE` shall not name it (C1510). `PROCEDURE` without `MODULE`, and a `GENERIC` statement, may name it when the generic specification is an operator, assignment, or defined input/output. They shall not name it when the generic specification is another generic name (C1505, C1512). Defined input/output adds every specific, and each specific has to have the `dtv` interface in 12.6.4.8.2. An extensible `dtv` type uses `CLASS` (C1236).

The draft syntax permits `GENERIC` and `BIND(C)` on the same initial statement and contains no blanket prohibition. Each residual specific still has to satisfy the interoperability requirements. A nonempty explicit `NAME=` applied to several generated procedures appears to give several entities one binding label, conflicting with global-identifier uniqueness in 20.2. By contrast:

- a singleton expansion can have one explicit nonempty binding label without a duplicate-label problem;
- `NAME=""` gives every generated procedure no binding label under 19.10.2 p2, so a multi-specific family avoids duplicate external identifiers; and
- an internal `BIND(C)` procedure without `NAME=` has no binding label under 19.10.2 p2, independently of its generated-specific count.

For a noninternal multi-specific generic with `BIND(C)` and no `NAME=`, deriving the default lower-case label for unnamed specifics remains unclear. These cases are quarantined as `generic-bind-c`; the suite records positive and negative observations without turning either blanket policy into settled conformance.

`PROCEDURE_NAME` from `ISO_FORTRAN_ENV` is explicitly Unresolved Technical Issue 031 in 26-007r1. The specifics are anonymous, and the draft does not determine whether the intrinsic returns the generic name or some other value inside a generated specific. No conformance profile requires a particular result.

## Distinguishability

15.4.3.4.5 is unchanged, and it applies to the generated specifics.

Two data dummies are distinguishable when neither is TKR-compatible with the other (or one is allocatable and the other is a non-`INTENT(IN)` pointer, and the other cases in p6). Nonpolymorphic dummies are type-compatible only with the same declared type. Different intrinsic types, different kinds, and different ranks are therefore distinguishable.

Polymorphic dummies are not symmetric. `CLASS(base)` is type-compatible with `CLASS(extended)` when `extended` extends `base`, so those two specifics are **not** distinguishable. `CLASS(left, right)` is legal only when neither type is compatible with the other: typically two unrelated extensible types. `TYPE(base, extended)` is legal because `TYPE` is not polymorphic.

For a named generic, every pair is all functions or all subroutines (C1517). A different function result never disambiguates a call. Length parameters do not participate in generic resolution, so character or PDT length alone cannot distinguish specifics. Assumed rank is TKR-compatible with any rank and can therefore create overlap with fixed-rank specifics. Optionality, effective argument position, and dummy names matter under C1517's positional-and-keyword rules; merely giving otherwise compatible procedures different optional layouts or ambiguous keyword paths is insufficient.

The special allocatable-versus-pointer distinction applies only with the exact intent conditions in 15.4.3.4.5 p6. An allocatable dummy and a pointer dummy with `INTENT(IN)` are not automatically distinguishable.

Elemental specifics are distinguished as if they were scalar. An array actual can still be an elemental reference, and if both an elemental and a nonelemental specific seem to match, the nonelemental one is chosen (15.5.5.2 paragraphs 1–2, C.10.6 paragraph 5). `tests/valid/elemental_tie_break.f90` is that case: a rank-1 actual selects the nonelemental rank-1 specific, and a rank-2 actual falls through to the elemental specific.

## Worked examples

### Static type selection

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

The caller writes `.twice. 2`. A defined unary operator is a prefix operator. The caller does not need access to `dbl`.

## Settled syntax and required diagnostics

Clause 4.2 requires a processor to contain the capability to detect and report violations of numbered syntax rules and constraints, unsupported kind values, and the other classes listed there. It does **not** require every diagnostic to be accompanied by a nonzero translation status. The conformance profile therefore verifies the intended diagnostic; requiring unsuccessful translation is a stricter runner policy.

| Rule | Settled requirement |
| --- | --- |
| C801 | A generic type declaration appears only in the specification part of a generic subprogram. Its conflict with a `MODULE GENERIC` interface body is quarantined separately rather than silently extending C801. |
| C802 | A generic declaration names one nonoptional dummy data object: not a local, function result, optional dummy, or two entities. |
| C803, C804 | An entity `*char-length` is used only when all listed types are character and its value is `*` or `:`. |
| C707, C715 | `TYPE` does not produce an abstract residual declaration; `CLASS` lists only extensible types. |
| C716 | A generic type list with no kind-generic item contains more than one item. |
| C717, C718 | Length parameters in a generic type spec are assumed or deferred; an intrinsic generic kind expression is rank one. |
| C725, C845 | Existing assumed-type and assumed-rank name-use restrictions continue to apply. `TYPE(*)` is not a permitted `SELECT GENERIC RANK` selector, and an assumed-rank type-generic dummy is not a permitted direct `SELECT GENERIC TYPE` selector under C845's literal list. |
| C719-C723 | A generic PDT has a kind parameter, valid keyword ordering and parameter coverage, length values `*`/`:`, scalar or rank-one kind values, and at least one rank-one kind value. |
| C826, C875 | Written rank/corank limits and processor maximum-rank bounds apply. Their conflict for processor-advertised ranks above 15 is quarantined. |
| C876 | An entity with a generic `RANK` clause has no `array-spec` in its entity declaration. |
| C877 | A `RANK` entity is a named constant, dummy data object, allocatable, or pointer. Plain locals and plain results are excluded. |
| C1155-C1158 | Rank selection uses a rank-generic dummy, has at most one default, and has consistent construct names. |
| C1159-C1163 | Type selection uses a type-generic dummy, has assumed length parameters under C1160, no duplicate type/kind guard, at most one default, and consistent names. Whether bare `CHARACTER(LEN=*)` is type-generic and whether `*` is permitted in this guard context are separate draft readings. |
| C1505, C1510, C1512 | A generic name is not named as a specific under another named generic, and `MODULE PROCEDURE` does not name a generic. Operator, assignment, and defined-I/O aggregation remain allowed. |
| C1511, C1513 | A procedure already specified in an accessible interface under a generic identifier is not inserted again through an interface block or `GENERIC` statement. |
| C1514-C1517 | Every pair sharing a generic identifier satisfies the relevant operator, assignment, I/O, or named-generic distinguishability rule. |
| C7132 | Constructor-like syntax is disambiguated in favor of a resolvable same-named generic function reference; it does not prohibit defining that overlapping generic interface. |
| C1537, C798 and procedure-pointer constraints | The generic identifier is not a specific procedure actual argument, type-bound target, or procedure-pointer target. |
| C1561, C1564 | A separate module definition has the same semantic characteristics and dummy names as its interface; `GENERIC` appears only in the permitted module/internal or `MODULE` interface contexts. |
| C1582-C1585, C1589 | A generic is module or internal, has no generic internal subprogram, no alternate-return dummy, explicit interfaces for dummy procedures, and no `ENTRY`. |
| C1555-C1557 | Prefix specifications are not duplicated and contradictory purity or recursion prefixes are not combined. |
| C15135-C15137 | Every elemental specific has eligible scalar dummies and result and the required intents. |
| 4.2(4) | Use of an unsupported intrinsic kind value is detectable and reportable. A runtime branch does not suppress this obligation. |

The BNF spelling `DECLARED TYPE IS` / `DECLARED TYPE DEFAULT` is settled despite C1162's shortened phrase “TYPE DEFAULT”. Similarly, C877 controls the invalid result declarations in 15.6.2.4 NOTES 7 and 8; examples do not override a numbered constraint.

## Unnumbered requirements and enhanced diagnostics

These rules affect program conformance, but their violations are not automatically among the diagnostics required by 4.2. The optional enhanced profile can demand a matching diagnostic and, in a still stricter mode, unsuccessful translation.

| Text | Requirement |
| --- | --- |
| 15.6.2.4 p2 | After generic selections are pruned, every residual specific conforms. Independently generic mixed kinds cannot hide an invalid `MOD` call merely because the program never invokes that combination. |
| 15.6.2.1 p3 | A `NON_RECURSIVE` generic does not directly or indirectly invoke any specific defined by that subprogram. |
| 11.1.10.2 | Each specific retains at most one rank block; overlapping guards that both match one rank are nonconforming. |
| 11.1.10.2, 11.1.11.2, 11.2 | Transfer to the end of a selection is allowed only from within it; branching into a selection is not. A named `EXIT` from within is allowed. |
| 15.4.3.4.2-.4 | Every contributed operator, assignment, or defined-I/O specific has the required arity, intents, result, TKR, and `dtv` interface, including conflicts with intrinsic operation or assignment. |
| 15.5.2 | After selection, actual arguments meet the selected specific's definability, allocatable, pointer, optional, keyword, type, kind, and rank requirements. |
| Generic resolution | A reference must resolve to an eligible specific, intrinsic fallback, or constructor interpretation. |

Empty expansions and `GENERIC` plus `BIND(C)` are **not** in this table because the draft does not establish the blanket outcomes previously asserted for them.

## Changes since 25-156r1

The paper's straw votes that the draft kept: kind values are a rank-one array, not `*` (alternative 1a); a derived-type kind parameter may be scalar or rank one, and at least one is rank one (1.5b); duplicate kinds and duplicate type/kind pairs collapse (2a, 3a); duplicate ranks collapse and the dummy stays generic (5b); duplicate ranks inside one `SELECT GENERIC RANK` list are ignored (6b).

The draft then changed the feature further:

| Paper | Draft 26-007r1 |
| --- | --- |
| `TYPE IS` / `TYPE DEFAULT` | `DECLARED TYPE IS` / `DECLARED TYPE DEFAULT` |
| `RANKOF(x)` as a rank clause | `RANK(RANK(x))` |
| Open range `RANK(1:)` | Both bounds required, for example `RANK(1:7)` |
| `SELECT GENERIC RANK (y)` when `y` is `RANK(RANK(x))` | The selector is the rank-generic dummy |
| `TYPE(t1, t2) :: x, y` in examples | One name per generic type declaration (C802). The paper's own syntax already said a single `generic-dummy-arg-decl`; the draft's examples agree. |
| `RANK(*)` excluded from generic-rank guards by a constraint | `*` is simply not a `rank-spec` |
| Several constraints about not mentioning a generic dummy except as `KIND(x)` or `RANK(x)` | Removed. 15.6.2.4 p2 (check each specific after substitution) does that work. |

## Unresolved draft interpretations

These rows are non-gating by default. The suite records an intended reading only when one is explicitly selected; it does not label a processor nonconforming for taking the other side.

| Reading ID | Draft tension | Treatment |
| --- | --- | --- |
| `generic-interface-declarations` | C801 permits a generic declaration only in a generic subprogram, while 15.4.3.2 p4 permits a `MODULE GENERIC` interface body and 15.4.3.4.1 p2 says that body contributes all specifics. | Preserve the contribution rule, but quarantine interface bodies that need generic dummy declarations. |
| `assumed-length-guards` | C1160 requires every length parameter in a generic guard to be assumed. C736 permits `*` in a type guard specifically referencing 11.1.13, C7124 omits guards for PDT parameters, and 7.2 describes assumed values only for dummies, runtime `SELECT TYPE` associates, and character named constants. | Intended reading: generic guards are also permitted contexts; guard lengths are `*`, not `:`, while kind parameters may use declared defaults. |
| `empty-expansion` | `RANK(1:0)` denotes no ranks, and a rank-one kind array can have size zero, but no explicit rule requires a nonempty factor or generic set. | Do not require either acceptance or rejection. |
| `generic-bind-c` | Syntax allows both prefixes. Multiple specifics with one nonempty explicit label conflict with 20.2, but singleton expansion and `NAME=""` do not have that duplicate-label problem; unnamed-specific default labels are also unclear. | Exercise individual cases only under the selected reading; no blanket ban. |
| `extended-rank-limit` | C826 says rank plus corank is at most 15; `MAX_RANK` examples describe rank and corank 24. | Default to literal bounds satisfying both. Processor-advertised ranks above 15 are opt-in. |
| `character-generic-parse` | `CHARACTER(LEN=*)` or `CHARACTER(*)` with no kind expression is read as a singleton generic intrinsic spec. | The positive observation uses `DECLARED TYPE DEFAULT`, avoiding the separate assumed-length-guard question. |
| `character-ordinary-parse` | The same token sequence is read as the long-standing ordinary assumed-length character declaration and is not type-generic. | The negative selector observation also uses `DECLARED TYPE DEFAULT`, isolating parsing from C736/C1160. |
| `mixed-length-dedup` | 7.3.2.2 p3 collapses duplicate type/kind combinations but does not say which assumed/deferred length mode remains when otherwise equal entries differ in mode. | Do not invent a retained mode or claim the entries necessarily remain distinct. |
| `template-integration` | R1608 admits ordinary function and subroutine subprograms in a template subprogram part, while C1582 says a generic subprogram is a module or internal subprogram. The draft does not state whether the template-contained case qualifies. | Observe the instantiated generic only under the selected reading; do not infer a default conformance outcome. |
| UTI031 (`PROCEDURE_NAME`) | Generated specifics are anonymous, and 17.10.2.29 does not define a better result than the generic name. | No required result until the unresolved technical issue is closed. |

Two nearby issues are **not** left unresolved here. C1162's shortened words do not replace the R1157 BNF, and C877 controls ranked results despite the invalid examples in NOTES 7 and 8. A guard outside the dummy's set and a selection with no matching guard are also explicitly valid consequences of the selection semantics.

The two character parse readings can be selected together for non-gating comparison. A runner profile does not permit `--gate-drafts` to gate both mutually exclusive readings in the same run; either can be gated separately as an explicit profile policy, without converting it into settled conformance.

## Tests

The permanent requirement index is [conformance-coverage.md](conformance-coverage.md). Fixture metadata, not directory name alone, determines capability requirements, diagnostic class, draft reading, expected phase, runtime marker, and image count.

The reconciled inventory contains 267 cases and 278 Fortran sources: 74 positive cases, 191 compile-time diagnostic cases, and 2 expected runtime-termination cases. Twenty-three cases are draft-tagged. One positive case, `valid/language_array_domains_expanded.f90`, is deliberately ordinary explicit-specialization control code and is not generic-subprogram execution. `tests/run.sh check` reports zero metadata errors and zero warnings.

`tests/run.sh` remains the entry point to a Python 3.9-compatible standard-library backend. It uses isolated work directories, validates compiler/source/output existence, enforces timeouts, handles quoted compiler wrappers and flags, and treats a directory of `.f90` or `.f` sources as one separately compiled case in lexical order. Test-relative selectors and paths containing spaces are supported.

```sh
./tests/run.sh check
./tests/run.sh list --json valid/
FC=lfortran ./tests/run.sh --mode conformance valid/factorial.f90
FC=lfortran ./tests/run.sh --strict invalid_compile_time/
./tests/run.sh --draft empty-expansion \
  draft_interpretations/negative/empty_rank_range.f90
./tests/run.sh --draft generic-bind-c --gate-drafts \
  draft_interpretations/negative/bind_c_one_specific.f90
FC=lfortran ./tests/run.sh inventory --json
FC=lfortran ./tests/run.sh generate --output build/generated-cases --force
```

Normal execution includes processor inventory and generated kind/rank coverage; `--no-generated` disables that part. Multi-image and timeout configuration is explicit, for example `--launcher 'cafrun -n {images} {exe}' --compile-timeout 120 --run-timeout 60`. Defaults are 60 seconds per compile/link command and 20 seconds per executable. `./tests/run.sh --help` is the complete reference.

Vendor-specific diagnostic expectations for compile-time negative cases can be supplied without changing a case's expected phase or required/enhanced classification:

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

Use it, for example, as `FC=vendor-fc ./tests/run.sh --diagnostic-expectations vendor-diagnostics.json invalid_compile_time/`. `marked` requires a diagnostic at a `TEST-ERROR-HERE` target, `source` requires a source file belonging to the case, and `case-context` accepts a matching diagnostic record without a usable source coordinate. Case overrides take precedence over rule overrides; ambiguous multiple rule overrides require a case override. Human and JSON output disclose the active overrides. Fortran specifies diagnostic obligations, not diagnostic wording or source coordinates, so these are runner matching rules rather than language requirements.

The profiles have different claims:

- **Conformance** runs settled positive cases and verifies required diagnostics. A matching diagnostic can satisfy the 4.2 detect-and-report obligation even when a compiler continues and returns status zero.
- **Strict/enhanced diagnostics** can additionally require unsuccessful translation and request diagnostics for unnumbered requirements.
- **Draft readings** are selected with `--draft` and are non-gating by default. `--gate-drafts` can make selected results gating for that runner profile, but this policy never makes the interpretation settled standard conformance.

A negative case must match the intended diagnostic and phase. Rejection for unknown generic syntax, an unrelated source error, a missing-main link failure, or echoed source text is not a pass. Link or compile-or-link expectations are used only when that is the rule being tested.

Runtime error-termination cases print an exact `TEST-STOP:` line, execute `FLUSH(output_unit)` so the marker survives termination, and then execute the intended `ERROR STOP`; they print `TEST-UNEXPECTED-RETURN:` if execution continues. The runner parses that actual statement and calibrates the same literal stop-code form—absent, character, or integer—and the same literal `QUIET=` value with the same compiler, flags, and launcher. It does not require one fixed diagnostic message. Dynamic stop codes or `QUIET` expressions cannot be calibrated by this profile. Clause 11.4 makes the externally observed stop code and process status processor dependent; neither “nonzero below 128” nor any fixed signal convention is a portable Fortran requirement.

Kind-family fixtures use `INTEGER_KINDS`, `REAL_KINDS`, `LOGICAL_KINDS`, and `CHARACTER_KINDS`, and generated callers exercise **every reported kind value**. Real-kind coverage includes corresponding complex specifics. Generated state checks distinguish each kind, each intrinsic type, scalar versus rank one, and their joint type/kind/rank product. `INT32`, `INT64`, `REAL32`, `REAL64`, ASCII, and ISO 10646 are optional capabilities; zero is a valid supported kind, while negative named-kind values mean unavailable. Missing optional capabilities produce explicit skips, not false full-coverage claims.

The generated rank program invokes every generic specific from rank zero through the selected bound and invokes each twice to verify per-rank saved state; merely constructing one ordinary array at the highest rank is not counted as intervening generic coverage. The portable profile uses a bound satisfying both C875 and the written C826 limit. Larger processor-advertised ranks are exercised only with the `extended-rank-limit` reading. Multi-image fixtures similarly require a configured launcher; absence of one is an explicit skip.

Isolated probes on 22 September 2026 confirmed that the installed gfortran 16.1, Flang 22 development build, and LFortran 0.66 development build all reject even a `GENERIC` function with no generic dummy. The same installations also lack `TYPEOF`, `RANK` clauses, `ISO_FORTRAN_ENV`'s `MAX_RANK`, and `DEFAULT KIND`. Their rejection of a new-syntax negative fixture therefore does **not** validate that fixture's intended rule.

Local validation completed 25 runner self-tests, and the ordinary `language_array_domains_expanded` control compiled and ran successfully with all three installed compilers. No `GENERIC` fixture execution has been validated locally. Until prerequisite and diagnostic gating establishes that a compiler reached the rule under test, repetitive full-suite attempts with those installations add no feature-level evidence. Runner self-tests, metadata checks, ordinary Fortran controls, and manually written explicit-specialization equivalents validate the harness and ordinary semantics only. No finite suite proves complete conformance or absence of missing corner cases.
