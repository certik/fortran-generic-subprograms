! TEST-RULE: C826 C875
! TEST-DRAFT: literal-rank-limit
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C826|rank.*corank.*(fifteen|15)|rank.*maximum|more than 15 dimensions
! TEST-ERROR-PHASE: compile
! Selected literal-rank-limit reading only. Read literally, C826 makes rank 15
! plus corank 1 a numbered-constraint violation, so the diagnostic is required
! under that profile. The opposing extended-rank-limit reading lets a
! processor-advertised MAX_RANK(1) above 14 govern instead; this fixture is not
! evidence against a processor under that reading.
module reject_rank_corank_sum_above_fifteen_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(15) :: x[*]
  end subroutine
end module
