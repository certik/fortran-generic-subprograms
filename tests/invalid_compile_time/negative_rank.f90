! TEST-RULE: C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C875|rank.*nonnegative|negative.*rank
! TEST-ERROR-PHASE: compile
! Invalid: C875. A rank bound is nonnegative.
module negative_rank_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(-1:1) :: x
  end subroutine
end module
