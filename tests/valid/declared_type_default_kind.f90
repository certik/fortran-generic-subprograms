! TEST-RULE: R708 R1157 8.7 11.1.11.2
! TEST-REQUIRES: int32 int64 real32 real64
! DECLARED TYPE IS (REAL) matches default real only, not every real kind.
! DECLARED TYPE IS (INTEGER) matches default integer only (11.1.11.2).
module declared_type_default_kind_m
  use, intrinsic :: iso_fortran_env, only: real32, real64, int32, int64
  implicit none
contains
  generic function real_code(x) result(n)
    real([real32, real64]), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (real)
      n = 1
    declared type default
      n = 2
    end select
  end function

  generic function int_code(x) result(n)
    integer([int32, int64]), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer)
      n = 1
    declared type default
      n = 2
    end select
  end function
end module

program declared_type_default_kind_p
  use, intrinsic :: iso_fortran_env, only: real32, real64, int32, int64
  use declared_type_default_kind_m
  implicit none
  if (real32 < 0 .or. real64 < 0) error stop "need real32 and real64"
  if (int32 < 0 .or. int64 < 0) error stop "need int32 and int64"
  if (kind(1.0) == real32) then
    if (real_code(1.0_real32) /= 1) error stop "real32 is default real"
  else
    if (real_code(1.0_real32) /= 2) error stop "real32 is not default real"
  end if
  if (kind(1.0) == real64) then
    if (real_code(1.0_real64) /= 1) error stop "real64 is default real"
  else
    if (real_code(1.0_real64) /= 2) error stop "real64 is not default real"
  end if
  if (kind(0) == int32) then
    if (int_code(1_int32) /= 1) error stop "int32 is default integer"
  else
    if (int_code(1_int32) /= 2) error stop "int32 is not default integer"
  end if
  if (kind(0) == int64) then
    if (int_code(1_int64) /= 1) error stop "int64 is default integer"
  else
    if (int_code(1_int64) /= 2) error stop "int64 is not default integer"
  end if
end program
