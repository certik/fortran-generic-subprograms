! TEST-RULE: C1557
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1557|RECURSIVE.*NON_RECURSIVE|incompatible.*prefix
! TEST-ERROR-PHASE: compile
module reject_recursive_nonrecursive_prefix_m
  implicit none
contains
  ! TEST-ERROR-HERE
  recursive non_recursive generic subroutine s(x)
    integer, intent(in) :: x
  end subroutine
end module
