! TEST-RULE: C1515 15.4.3.3 15.4.3.4.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1515|ambiguous.*assignment|not distinguishable|ambiguous.*generic
! TEST-ERROR-PHASE: compile
! The GENERIC statement contributes every generated specific of the generic
! subroutine ASSIGN_BOX plus the named ASSIGN_BOX_VECTOR to ASSIGNMENT(=)
! (15.4.3.3 p3). The family is valid alone: its specifics differ in the rank
! of RHS. Its generated rank-one specific and the named rank-one subroutine
! have no distinguishable dummy at either position, which violates C1515.
! Checking only named-versus-named pairs cannot find the conflict.
module reject_assignment_ambiguous_m
  implicit none
  type :: box
    integer :: value
  end type
  ! TEST-ERROR-HERE
  generic :: assignment(=) => assign_box, assign_box_vector
contains
  ! TEST-ERROR-HERE
  generic subroutine assign_box(lhs, rhs)
    type(box), intent(out) :: lhs
    integer, intent(in), rank(0:1) :: rhs
    lhs%value = 1
  end subroutine

  ! TEST-ERROR-HERE
  subroutine assign_box_vector(lhs, rhs)
    type(box), intent(inout) :: lhs
    integer, intent(in) :: rhs(:)
    lhs%value = size(rhs)
  end subroutine
end module
