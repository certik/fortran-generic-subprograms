! TEST-RULE: C709 C713 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C709|CLASSOF.*(dummy|allocatable|pointer)|polymorphic.*local
! TEST-ERROR-PHASE: compile
module audit_reject_classof_plain_local_m
  implicit none
  type :: base
    integer :: value
  end type
  type, extends(base) :: child
    integer :: extra
  end type
contains
  generic subroutine reject_plain_local(object)
    type(base, child), intent(in) :: object
    ! OBJECT is generated but always nonintrinsic, so C713 is satisfied.
    ! TEST-ERROR-HERE
    classof(object) :: copy
  end subroutine
end module
