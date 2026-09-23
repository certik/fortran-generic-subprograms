! TEST-RULE: C1517 C802 15.4.3.4.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|optional.*not distinguish
! TEST-ERROR-PHASE: compile
! Two same-name generic subprograms extend one generic name (15.6.2.4 NOTE 4).
! The generic dummy X is nonoptional as C802 requires; the ordinary dummy Y
! is optional. Each family is valid alone. The generated rank-one pair
! CONSUME(X) and CONSUME(X, [Y]) is not distinguished by an optional dummy,
! so CALL CONSUME(rank-one) would be ambiguous and C1517 is violated.
module reject_generic_optional_ambiguity_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    integer, intent(in), rank(0:1) :: x
  end subroutine

  ! TEST-ERROR-HERE
  generic subroutine consume(x, y)
    integer, intent(in), rank(1:2) :: x
    real, intent(in), optional :: y
  end subroutine
end module
