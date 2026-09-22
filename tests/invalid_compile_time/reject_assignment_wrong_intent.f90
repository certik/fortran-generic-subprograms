! TEST-RULE: 15.4.3.4.3
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined assignment.*INTENT|first argument.*INTENT
! TEST-ERROR-PHASE: compile
module reject_assignment_wrong_intent_m
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
  generic subroutine assign(lhs, rhs)
    type(box_t), intent(in) :: lhs
    integer, intent(in) :: rhs
  end subroutine
end module
