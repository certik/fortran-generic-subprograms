! TEST-RULE: C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C875|rank.*maximum|maximum.*rank
! TEST-ERROR-PHASE: compile
! Invalid: C875. A rank bound is at most MAX_RANK() for a non-coarray.
module rank_above_max_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(0:max_rank()+1) :: x
  end subroutine
end module
