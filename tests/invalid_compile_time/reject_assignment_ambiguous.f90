! TEST-RULE: C1515
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1515|ambiguous.*assignment|not distinguishable
! TEST-ERROR-PHASE: compile
module reject_assignment_ambiguous_m
  implicit none
  type :: box
    integer :: value
  end type
  ! TEST-ERROR-HERE
  interface assignment(=)
    module procedure assign_one
    ! TEST-ERROR-HERE
    module procedure assign_two
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine assign_one(lhs, rhs)
    type(box), intent(out) :: lhs
    integer, intent(in) :: rhs
    lhs%value = rhs
  end subroutine

  ! TEST-ERROR-HERE
  subroutine assign_two(lhs, rhs)
    type(box), intent(out) :: lhs
    integer, intent(in) :: rhs
    lhs%value = rhs
  end subroutine
end module
