! TEST-RULE: C712
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C712|TYPEOF.*abstract|abstract type.*TYPEOF
! TEST-ERROR-PHASE: compile
module audit_reject_typeof_abstract_m
  implicit none
  type, abstract :: abstract_base
    integer :: value
  end type
contains
  generic subroutine reject_abstract(tag, object)
    type(integer, real), intent(in) :: tag
    class(abstract_base), intent(in) :: object
    ! TEST-ERROR-HERE
    typeof(object) :: copy
  end subroutine
end module
