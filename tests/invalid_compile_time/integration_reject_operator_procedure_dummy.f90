! TEST-RULE: C1585 15.4.3.4.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: operator.*(dummy procedure|procedure argument|data object)|(dummy procedure|procedure argument).*operator|operand.*(procedure|data object)|\.[A-Za-z]+\. function.*must be a data object|argument of operator interface.*INTENT\(IN\)
! TEST-ERROR-PHASE: compile
! Operator dummies are dummy data objects (15.4.3.4.2 p1). The explicit
! interface satisfies C1585, but every generated specific has a dummy
! procedure operand.
module integration_reject_operator_procedure_dummy_m
  implicit none
  abstract interface
    function unary(a) result(b)
      integer, intent(in) :: a
      integer :: b
    end function
  end interface
  interface operator(.through.)
    ! TEST-ERROR-HERE
    procedure through
  end interface
contains
  ! TEST-ERROR-HERE
  generic function through(x, f) result(y)
    type(integer, real), intent(in) :: x
    ! TEST-ERROR-HERE
    procedure(unary) :: f
    typeof(x) :: y
    y = x + f(1)
  end function
end module
