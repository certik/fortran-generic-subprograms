! TEST-RULE: C1517 15.4.3.4.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|not distinguishable|assumed-rank.*not distinguish|ambiguous.*generic
! TEST-ERROR-PHASE: compile
! Two same-name generic subprograms extend one generic name (15.6.2.4 NOTE 4).
! The first generates assumed-rank INTEGER and REAL specifics; the second
! generates rank-one INTEGER and LOGICAL specifics. Each family is valid
! alone. Assumed rank is TKR compatible with every rank (15.4.3.4.5 p2), so
! only the generated INTEGER(..) and INTEGER rank-one pair violates C1517.
module reject_generic_assumed_rank_overlap_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    ! TEST-ERROR-HERE
    type(integer, real), intent(in) :: x(..)
  end subroutine

  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    ! TEST-ERROR-HERE
    type(integer, logical), intent(in), rank(1) :: x
  end subroutine
end module
