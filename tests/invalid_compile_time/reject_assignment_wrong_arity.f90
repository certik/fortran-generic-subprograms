! TEST-RULE: 15.4.3.4.3
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined assignment.*two.*dummy|assignment.*two.*arguments|assignment.*number of arguments
! TEST-ERROR-PHASE: compile
module reject_assignment_wrong_arity_m
  implicit none
  type :: box_t
    integer :: value
  end type
  interface assignment(=)
    ! TEST-ERROR-HERE
    procedure assign
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine assign(lhs)
    type(box_t), intent(out) :: lhs
  end subroutine
end module
