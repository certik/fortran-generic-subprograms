! TEST-RULE: C712
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C712|TYPEOF.*unlimited polymorphic|unlimited polymorphic.*TYPEOF
! TEST-ERROR-PHASE: compile
module audit_reject_typeof_unlimited_polymorphic_m
  implicit none
contains
  generic subroutine reject_unlimited(tag, object)
    type(integer, real), intent(in) :: tag
    class(*), intent(in) :: object
    ! TEST-ERROR-HERE
    typeof(object) :: copy
  end subroutine
end module
