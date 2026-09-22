! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|single entity|one dummy.*generic declaration
! TEST-ERROR-PHASE: compile
module reject_rank_generic_multiple_entities_m
  implicit none
contains
  generic subroutine s(x, y)
    ! TEST-ERROR-HERE
    integer, rank(0:1) :: x, y
  end subroutine
end module
