! TEST-RULE: 15.4.3.4.2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: operator.*dummy.*INTENT.IN|operator interface.*INTENT|defined operator.*intent
! TEST-ERROR-PHASE: compile
module reject_operator_missing_intent_m
  implicit none
  interface operator(.identity.)
    ! TEST-ERROR-HERE
    procedure identity
  end interface
contains
  ! TEST-ERROR-HERE
  generic integer function identity(x)
    integer :: x
    identity = x
  end function
end module
