! TEST-RULE: R707 R708 C718 15.6.2.4
! TEST-REQUIRES: int32 int64
! TEST-PASS: integer_kinds
! INTEGER(INTEGER_KINDS) and INTEGER(KIND=[INT32, INT64]) (7.3.2.2, C718).
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

  ! One specific per element of INTEGER_KINDS. The body is the same check
  ! for every kind the processor supports.
  generic subroutine check(n)
    integer(integer_kinds), intent(in) :: n
    if (plus1(n) /= n + 1) error stop "check plus1"
    if (kind(plus1(n)) /= kind(n)) error stop "check kind"
  end subroutine
end module

program integer_kinds_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use integer_kinds_m
  implicit none
  ! These ranges are supported on every processor. A supported kind value can
  ! be zero; only a negative result denotes an unsupported request.
  ! A literal such as 1_int8 is not portable: INT8 may be negative, and a
  ! kind parameter that does not exist is a constraint violation even in a
  ! branch the program never takes.
  integer, parameter :: k2 = selected_int_kind(2)
  integer, parameter :: k4 = selected_int_kind(4)
  integer, parameter :: k9 = selected_int_kind(9)
  integer, parameter :: k18 = selected_int_kind(18)
  if (int32 < 0 .or. int64 < 0) error stop "need int32 and int64"
  if (k2 < 0 .or. k4 < 0 .or. k9 < 0 .or. k18 < 0) error stop "selected_int_kind"
  if (plus1(5) /= 6) error stop "default integer"
  if (plus1(5_int32) /= 6_int32) error stop "int32"
  if (plus1(5_int64) /= 6_int64) error stop "int64"
  if (kind(plus1(5_int64)) /= int64) error stop "result kind int64"
  if (kind(plus1(5_int32)) /= int32) error stop "result kind int32"
  if (plus1_named(8_int32) /= 9_int32) error stop "named kind array int32"
  if (plus1_named(8_int64) /= 9_int64) error stop "named kind array int64"
  call check(1_k2)
  call check(1_k4)
  call check(1_k9)
  call check(1_k18)
  call check(1)
  call check(1_int32)
  call check(1_int64)
  print '(a)', 'TEST-PASS: integer_kinds'
end program
