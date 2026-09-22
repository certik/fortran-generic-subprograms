! TEST-RULE: C826 C875
! TEST-DRAFT: extended-rank-limit
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: C826|rank.*corank.*fifteen|rank.*maximum
! TEST-ERROR-PHASE: compile
module reject_rank_corank_sum_above_fifteen_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(15) :: x[*]
  end subroutine
end module
