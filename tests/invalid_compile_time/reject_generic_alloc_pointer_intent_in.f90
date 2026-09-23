! TEST-RULE: C1517 15.4.3.4.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|not distinguishable|ALLOCATABLE.*POINTER.*INTENT.IN|ambiguous.*generic
! TEST-ERROR-PHASE: compile
! Two same-name generic subprograms extend one generic name (15.6.2.4 NOTE 4).
! Each family is valid alone: its specifics differ in rank. Across them, only
! the two generated rank-one specifics overlap: an ALLOCATABLE dummy and a
! POINTER dummy are distinguishable only when the pointer is not INTENT(IN)
! (15.4.3.4.5 p6), so that pair violates C1517. No named specific exists, so
! checking only named procedures cannot find the conflict.
module reject_generic_alloc_pointer_intent_in_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    ! TEST-ERROR-HERE
    integer, allocatable, intent(in), rank(0:1) :: x
  end subroutine

  ! TEST-ERROR-HERE
  generic subroutine consume(x)
    ! TEST-ERROR-HERE
    integer, pointer, intent(in), rank(1:2) :: x
  end subroutine
end module
