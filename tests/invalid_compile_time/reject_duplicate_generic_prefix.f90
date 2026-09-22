! TEST-RULE: C1555
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1555|GENERIC.*more than once|duplicate.*GENERIC
! TEST-ERROR-PHASE: compile
module reject_duplicate_generic_prefix_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic generic subroutine s(x)
    integer, intent(in) :: x
  end subroutine
end module
