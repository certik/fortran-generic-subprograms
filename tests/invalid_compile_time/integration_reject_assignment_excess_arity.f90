! TEST-RULE: 15.4.3.4.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: assignment.*(exactly two|two|number of|arguments|arity)|(too many|three).*(argument|dummy).*assignment
! TEST-ERROR-PHASE: compile
! Defined assignment subroutines have exactly two dummies (15.4.3.4.3 p2);
! every generated specific has three. The one-dummy case is
! reject_assignment_wrong_arity.f90.
module integration_reject_assignment_excess_arity_m
  implicit none
  type :: box
    integer :: n = 0
  end type
  interface assignment(=)
    ! TEST-ERROR-HERE
    procedure put
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine put(lhs, rhs, extra)
    type(box), intent(inout) :: lhs
    type(integer, real), intent(in) :: rhs
    integer, intent(in) :: extra
    lhs%n = int(rhs) + extra
  end subroutine
end module
