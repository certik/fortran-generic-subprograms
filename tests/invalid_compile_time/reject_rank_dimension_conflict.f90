! TEST-RULE: C819 8.5.17
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C819|DIMENSION.*more than once|conflicting.*(DIMENSION|RANK)
! TEST-ERROR-PHASE: compile
module reject_rank_dimension_conflict_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, dimension(:), rank(0:1) :: x
  end subroutine
end module
