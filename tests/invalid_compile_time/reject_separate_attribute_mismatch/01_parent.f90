! TEST-RULE: C1561
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|INTENT.*does not match|characteristics.*interface
! TEST-ERROR-PHASE: compile
module reject_separate_attribute_mismatch_m
  implicit none
  interface
    module generic subroutine s(x)
      integer, intent(in) :: x
    end subroutine
  end interface
end module
