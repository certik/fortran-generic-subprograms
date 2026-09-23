! TEST-RULE: C874 8.5.16 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C874|PROTECTED_TARGET.*INTENT|INTENT.*PROTECTED_TARGET|protected target.*intent
! TEST-ERROR-PHASE: compile
! The PROTECTED_TARGET pointer actual selects the integer scalar specific,
! whose nonpointer dummy lacks INTENT(IN) (C874). The dummy has no INTENT
! at all, so the actual is not in a variable definition context
! (20.6.7 item 10) and C866 is not also violated.
module integration_reject_protected_target_intent_m
  implicit none
contains
  generic function peek(x) result(total)
    type(integer, real), rank(0:1) :: x
    real :: total
    total = real(sum([x]))
  end function
end module

program integration_reject_protected_target_intent_p
  use integration_reject_protected_target_intent_m
  implicit none
  integer, pointer, protected_target :: shared
  allocate(shared, source=3)
  ! TEST-ERROR-HERE
  if (peek(shared) /= 3.0) error stop "unreachable"
end program
