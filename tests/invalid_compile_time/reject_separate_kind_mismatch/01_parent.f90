! TEST-RULE: C1561
! TEST-REQUIRES: int32 int64
! TEST-DRAFT: generic-interface-declarations
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|kind.*does not match|different.*kind.*interface
! TEST-ERROR-PHASE: compile
module reject_separate_kind_mismatch_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
  interface
    module generic subroutine s(x)
      use, intrinsic :: iso_fortran_env, only: int32, int64
      integer([int32, int64]) :: x
    end subroutine
  end interface
end module
