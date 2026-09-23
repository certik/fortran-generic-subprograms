! TEST-RULE: C711
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C711|TYPEOF.*previously.*declared|no implicit type|used before.*declared
! TEST-ERROR-PHASE: compile
module audit_reject_typeof_untyped_forward_m
  implicit none
contains
  generic subroutine reject_untyped_forward(tag)
    type(integer, real), intent(in) :: tag
    ! TEST-ERROR-HERE
    typeof(later_value) :: copy
    integer :: later_value
  end subroutine
end module
