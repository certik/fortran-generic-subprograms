! TEST-RULE: C1517 7.2 15.4.3.4.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|character length.*not distinguish
! TEST-ERROR-PHASE: compile
! Two same-name generic subprograms extend one generic name (15.6.2.4 NOTE 4).
! Each family is valid alone: its specifics differ in rank. Length is not a
! kind type parameter and does not make dummies TKR distinguishable, so only
! the generated rank-one LEN=1 and rank-one LEN=2 pair violates C1517.
module reject_generic_length_only_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    ! TEST-ERROR-HERE
    character(len=1), intent(in), rank(0:1) :: x
  end subroutine

  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    ! TEST-ERROR-HERE
    character(len=2), intent(in), rank(1:2) :: x
  end subroutine
end module
