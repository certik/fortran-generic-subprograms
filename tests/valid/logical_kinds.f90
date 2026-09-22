! TEST-RULE: R707 R708 C718 15.6.2.4
! LOGICAL(LOGICAL_KINDS): one specific per logical kind (7.3.2.2).
module logical_kinds_m
  use, intrinsic :: iso_fortran_env, only: logical_kinds
  implicit none
contains
  generic function lnot(x) result(y)
    logical(logical_kinds), intent(in) :: x
    typeof(x) :: y
    y = .not. x
  end function

  generic subroutine check(x)
    logical(logical_kinds), intent(in) :: x
    if (lnot(lnot(x)) .neqv. x) error stop "double not"
    if (kind(lnot(x)) /= kind(x)) error stop "check kind"
  end subroutine
end module

program logical_kinds_p
  use, intrinsic :: iso_fortran_env, only: logical_kinds
  use logical_kinds_m
  implicit none
  integer, parameter :: lk = logical_kinds(1)
  logical(kind=lk) :: v
  if (lnot(.true.) .neqv. .false.) error stop "not true"
  if (lnot(.false.) .neqv. .true.) error stop "not false"
  if (kind(lnot(.true.)) /= kind(.true.)) error stop "logical kind"
  v = .true.
  if (lnot(v) .neqv. .false.) error stop "first logical kind"
  if (kind(lnot(v)) /= lk) error stop "first logical kind value"
  call check(.true.)
  call check(.false.)
  call check(v)
end program
