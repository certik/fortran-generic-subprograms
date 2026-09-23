! TEST-RULE: C709 C714
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C714|OPTIONAL.*deferred.*type parameter|CLASSOF.*optional.*deferred
! TEST-ERROR-PHASE: compile
module audit_reject_classof_optional_deferred_m
  implicit none
  type :: packet(n)
    integer, len :: n
    integer :: values(n)
  end type
contains
  generic subroutine reject_optional_deferred(tag, object)
    type(integer, real), intent(in) :: tag
    type(packet(:)), allocatable, intent(in), optional :: object
    ! TEST-ERROR-HERE
    classof(object), allocatable :: copy
  end subroutine
end module
