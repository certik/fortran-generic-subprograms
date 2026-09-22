! TEST-RULE: C1561
! TEST-DRAFT: generic-interface-declarations
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|rank.*does not match|different.*rank.*interface
! TEST-ERROR-PHASE: compile
module reject_separate_rank_mismatch_m
  implicit none
  interface
    module generic subroutine s(x)
      integer, rank(0:1) :: x
    end subroutine
  end interface
end module
