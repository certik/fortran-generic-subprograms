! TEST-RULE: C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C875|rank.*nonnegative|negative.*rank
! TEST-ERROR-PHASE: compile
module reject_rank_invalid_later_list_item_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(0, -1) :: x
  end subroutine
end module
