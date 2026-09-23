! TEST-RULE: C1517 15.4.3.4.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|keyword.*not distinguish
! TEST-ERROR-PHASE: compile
! Two same-name generic subprograms extend one generic name (15.6.2.4 NOTE 4).
! Their dummy names are in opposite orders, and each family is valid alone.
! The generated pair CONSUME(I=rank-one integer, R=real) and
! CONSUME(R=real, I=rank-one integer) differs by position but not by any
! dummy name, so CALL CONSUME(I=..., R=...) would be ambiguous and C1517 (4)
! is violated. Every other cross pair also differs in the rank of I.
module reject_generic_keyword_ambiguity_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine consume(i, r)
    integer, intent(in), rank(0:1) :: i
    real, intent(in) :: r
  end subroutine

  ! TEST-ERROR-HERE
  generic subroutine consume(r, i)
    real, intent(in) :: r
    integer, intent(in), rank(1:2) :: i
  end subroutine
end module
