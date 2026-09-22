! TEST-RULE: 15.4.3.4.2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: operator.*(one|two).*argument|zero.*argument.*operator
! TEST-ERROR-PHASE: compile
module reject_operator_zero_arity_m
  implicit none
  interface operator(.nullary.)
    ! TEST-ERROR-HERE
    procedure make_value
  end interface
contains
  ! TEST-ERROR-HERE
  generic integer function make_value()
    make_value = 0
  end function
end module
