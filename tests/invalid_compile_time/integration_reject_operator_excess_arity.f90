! TEST-RULE: 15.4.3.4.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: operator.*(one or two|two|number of|arguments|arity)|(too many|three).*(argument|dummy).*operator
! TEST-ERROR-PHASE: compile
! OPERATOR is not permitted for functions with more than two arguments
! (15.4.3.4.2 p1); every generated specific has three.
module integration_reject_operator_excess_arity_m
  implicit none
  interface operator(.mix.)
    ! TEST-ERROR-HERE
    procedure mix
  end interface
contains
  ! TEST-ERROR-HERE
  generic function mix(a, b, c) result(y)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b, c
    typeof(a) :: y
    y = a + b + c
  end function
end module
