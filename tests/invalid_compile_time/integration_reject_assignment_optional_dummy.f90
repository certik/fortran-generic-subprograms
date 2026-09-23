! TEST-RULE: 15.4.3.4.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: assignment.*(optional|OPTIONAL)|(optional|OPTIONAL).*assignment|nonoptional.*assignment
! TEST-ERROR-PHASE: compile
! Defined assignment dummies are nonoptional (15.4.3.4.3 p2). The generic
! first dummy cannot be optional (C802); the ordinary second dummy is.
module integration_reject_assignment_optional_dummy_m
  implicit none
  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type
  interface assignment(=)
    ! TEST-ERROR-HERE
    procedure put
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine put(lhs, rhs)
    type(box, bag), intent(inout) :: lhs
    ! TEST-ERROR-HERE
    integer, intent(in), optional :: rhs
    lhs%n = 0
    if (present(rhs)) lhs%n = rhs
  end subroutine
end module
