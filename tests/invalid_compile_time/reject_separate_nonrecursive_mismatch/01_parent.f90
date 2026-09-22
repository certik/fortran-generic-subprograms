! TEST-RULE: C1563
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1563|NON_RECURSIVE.*does not match|NON_RECURSIVE.*interface
! TEST-ERROR-PHASE: compile
module reject_separate_nonrecursive_mismatch_m
  implicit none
  interface
    module non_recursive generic subroutine s(x)
      integer, intent(in) :: x
    end subroutine
  end interface
end module
