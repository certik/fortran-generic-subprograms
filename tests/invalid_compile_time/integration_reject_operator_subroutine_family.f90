! TEST-RULE: 15.4.3.4.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: operator.*(function|subroutine)|(subroutine|not a function).*operator|defined operat.*function
! TEST-ERROR-PHASE: compile
! OPERATOR requires every specific to be a function (15.4.3.4.2 p1); this
! generic family expands to two subroutines.
module integration_reject_operator_subroutine_family_m
  implicit none
  interface operator(.bumped.)
    ! TEST-ERROR-HERE
    procedure bump
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine bump(x, y)
    type(integer, real), intent(in) :: x
    typeof(x), intent(in) :: y
    if (x /= y) continue
  end subroutine
end module
