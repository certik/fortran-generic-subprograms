! TEST-RULE: 15.5.5.2
! TEST-REQUIRES: int32 int64
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: no matching specific|kind.*does not match|generic.*kind
! TEST-ERROR-PHASE: compile
module reject_call_kind_no_match_m
  use, intrinsic :: iso_fortran_env, only: int64
  implicit none
contains
  generic subroutine s(x)
    integer([int64]), intent(in) :: x
  end subroutine
end module

program reject_call_kind_no_match_p
  use, intrinsic :: iso_fortran_env, only: int32
  use reject_call_kind_no_match_m
  implicit none
  ! TEST-ERROR-HERE
  call s(1_int32)
end program
