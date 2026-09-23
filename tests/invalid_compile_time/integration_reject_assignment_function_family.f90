! TEST-RULE: 15.4.3.4.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: assignment.*(subroutine|function)|(function|not a subroutine).*assignment|defined assignment.*subroutine
! TEST-ERROR-PHASE: compile
! ASSIGNMENT(=) requires subroutines (15.4.3.4.3 p1). The generated
! functions otherwise have the assignment dummy shape: INTENT(INOUT) then
! INTENT(IN).
module integration_reject_assignment_function_family_m
  implicit none
  type :: box
    integer :: n = 0
  end type
  interface assignment(=)
    ! TEST-ERROR-HERE
    procedure store
  end interface
contains
  ! TEST-ERROR-HERE
  generic function store(lhs, rhs) result(ok)
    type(box), intent(inout) :: lhs
    type(integer, real), intent(in) :: rhs
    logical :: ok
    lhs%n = int(rhs)
    ok = .true.
  end function
end module
