! TEST-RULE: 15.4.3.4.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: intrinsic assignment.*conflict|defined assignment.*intrinsic|assignment.*same type
! TEST-ERROR-PHASE: compile
module reject_assignment_generated_intrinsic_conflict_m
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
    type(integer, box_t), intent(out) :: lhs
    typeof(lhs), intent(in) :: rhs
  end subroutine
end module
