! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|generic.*declaration.*dummy|local.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C802. A generic type declaration declares a dummy, not a local.
module generic_local_m
  implicit none
contains
  generic subroutine s(x)
    integer :: x
    ! TEST-ERROR-HERE
    type(integer, real) :: y
  end subroutine
end module
