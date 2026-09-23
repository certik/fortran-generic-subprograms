! TEST-RULE: C713 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C713|CLASSOF.*intrinsic|intrinsic type.*CLASSOF
! TEST-ERROR-PHASE: compile
module audit_reject_classof_generated_intrinsic_m
  implicit none
contains
  generic subroutine reject_intrinsic(object)
    type(integer, real), intent(in) :: object
    ! TEST-ERROR-HERE
    classof(object), allocatable :: copy
  end subroutine
end module
