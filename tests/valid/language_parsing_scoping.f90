! TEST-RULE: R504 R705 R871 R872 C8112 C8113 C8114 8.7 11.1.11
! TEST-REQUIRES: int32 int64 real32 real64
! TEST-PASS: language_parsing_scoping
! Mixed-case keywords, continuations, nonreserved keyword identifiers, and
! scoped DEFAULT KIND statements. Unqualified guard type specs use the
! default kind of the guard's scoping unit.
module language_parsing_scoping_m
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
  default kind (integer=int64, real=real64)
  implicit none
contains
  GeNeRiC FuNcTiOn module_integer(x) ReSuLt(n)
    InTeGeR([int32, int64]), InTeNt(In) :: x
    integer(int64) :: n
    SeLeCt GeNeRiC TyPe (x)
    DeClArEd TyPe Is (InTeGeR)
      n = 6400 + int(x, int64)
    DeClArEd TyPe DeFaUlT
      n = 3200 + int(x, int64)
    EnD SeLeCt
  EnD FuNcTiOn

  generic function local_integer(x) result(n)
    default kind (integer=int32)
    implicit none
    integer([int32, int64]), intent(in) :: x
    integer(int64) :: n
    select generic type (x)
    declared type is (integer)
      n = 3200_int64 + int(x, int64)
    declared type default
      n = 6400_int64 + int(x, int64)
    end select
  end function

  generic function module_real(x) result(n)
    real([real32, real64]), intent(in) :: x
    integer(int64) :: n
    select generic type (x)
    declared type is (real)
      n = 6400 + nint(x, kind=int64)
    declared type default
      n = 3200 + nint(x, kind=int64)
    end select
  end function

  GeNeRiC FuNcTiOn keyword_names(generic, rank) &
      ReSuLt(default)
    TyPe(InTeGeR, &
         ReAl), InTeNt(In) :: generic
    integer(int64), intent(in) :: rank
    integer(int64) :: default, type, select, declared
    type = rank
    select = 10
    declared = 20
    SeLeCt GeNeRiC TyPe (generic)
    DeClArEd TyPe Is (InTeGeR)
      default = int(generic, int64) + type + select + declared
    DeClArEd TyPe Is (ReAl)
      default = nint(generic, kind=int64) + type + select + declared
    EnD SeLeCt
  EnD FuNcTiOn
end module

program language_parsing_scoping_p
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
  use language_parsing_scoping_m
  implicit none

  if (int32 < 0 .or. int64 < 0 .or. real32 < 0 .or. real64 < 0) &
    error stop "required named kinds"
  if (module_integer(5_int64) /= 6405_int64) error stop "module integer default"
  if (module_integer(5_int32) /= 3205_int64) error stop "module integer fallback"
  if (local_integer(5_int32) /= 3205_int64) error stop "local integer default"
  if (local_integer(5_int64) /= 6405_int64) error stop "local integer fallback"
  if (module_real(5.0_real64) /= 6405_int64) error stop "module real default"
  if (module_real(5.0_real32) /= 3205_int64) error stop "module real fallback"
  if (keyword_names(5_int64, 2_int64) /= 37_int64) error stop "keyword identifiers integer"
  if (keyword_names(5.0_real64, 3_int64) /= 38_int64) error stop "keyword identifiers real"
  print '(a)', 'TEST-PASS: language_parsing_scoping'
end program
