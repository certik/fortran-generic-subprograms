! INTEGER(INTEGER_KINDS) and INTEGER(KIND=[INT32, INT64]) (7.3.2.2, C718).
! Assumes INT32 and INT64 are supported kinds.
module integer_kinds_m
  use, intrinsic :: iso_fortran_env, only: integer_kinds, int32, int64
  implicit none
contains
  generic function plus1(n) result(r)
    integer(integer_kinds), intent(in) :: n
    typeof(n) :: r
    r = n + 1
  end function

  generic function plus1_named(n) result(r)
    integer, parameter :: ks(2) = [int32, int64]
    integer(kind=ks), intent(in) :: n
    typeof(n) :: r
    r = n + 1
  end function
end module

program integer_kinds_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use integer_kinds_m
  implicit none
  if (int32 <= 0 .or. int64 <= 0) error stop "need int32 and int64"
  if (plus1(5) /= 6) error stop "default integer"
  if (plus1(5_int32) /= 6_int32) error stop "int32"
  if (plus1(5_int64) /= 6_int64) error stop "int64"
  if (kind(plus1(5_int64)) /= int64) error stop "result kind int64"
  if (kind(plus1(5_int32)) /= int32) error stop "result kind int32"
  if (plus1_named(8_int32) /= 9_int32) error stop "named kind array int32"
  if (plus1_named(8_int64) /= 9_int64) error stop "named kind array int64"
end program
