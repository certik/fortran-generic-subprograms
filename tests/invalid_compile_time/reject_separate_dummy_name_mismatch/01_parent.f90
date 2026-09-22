! TEST-RULE: C1561
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|dummy.*name.*does not match|dummy argument names
! TEST-ERROR-PHASE: compile
module reject_separate_dummy_name_mismatch_m
  implicit none
  interface
    module generic subroutine s(x)
      integer, intent(in) :: x
    end subroutine
  end interface
end module
