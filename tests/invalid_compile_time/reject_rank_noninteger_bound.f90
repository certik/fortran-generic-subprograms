! TEST-RULE: R832 R833 C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: rank.*integer|integer.*rank bound|invalid.*RANK
! TEST-ERROR-PHASE: compile
module reject_rank_noninteger_bound_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(0:1.0) :: x
  end subroutine
end module
