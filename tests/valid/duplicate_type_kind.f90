! TEST-RULE: R705 R706 7.3.2.2 15.6.2.4
! TEST-REQUIRES: real64
! TEST-PASS: duplicate_type_kind
! TYPE(REAL(REAL64), DOUBLE PRECISION) collapses when those kinds match
! and stays two specifics when they differ (7.3.2.2 p2–p3). Both calls work
! either way.
module duplicate_type_kind_m
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
contains
  generic function twice(x) result(y)
    type(real(real64), double precision), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function
end module

program duplicate_type_kind_p
  use, intrinsic :: iso_fortran_env, only: real64
  use duplicate_type_kind_m
  implicit none
  if (real64 < 0) error stop "need real64"
  if (twice(1.0_real64) /= 2.0_real64) error stop "real64"
  if (twice(1.0d0) /= 2.0d0) error stop "double precision"
  if (kind(twice(1.0_real64)) /= real64) error stop "kind real64"
  if (kind(twice(1.0d0)) /= kind(1.0d0)) error stop "kind double"
  print '(a)', 'TEST-PASS: duplicate_type_kind'
end program
