! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|not distinguishable|assumed-rank.*not distinguish|ambiguous.*generic
! TEST-ERROR-PHASE: compile
module reject_generic_assumed_rank_overlap_m
  implicit none
  ! TEST-ERROR-HERE
  interface consume
    module procedure consume_scalar
    ! TEST-ERROR-HERE
    module procedure consume_any_rank
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine consume_scalar(x)
    integer, intent(in) :: x
  end subroutine

  ! TEST-ERROR-HERE
  subroutine consume_any_rank(x)
    integer, intent(in) :: x(..)
  end subroutine
end module
