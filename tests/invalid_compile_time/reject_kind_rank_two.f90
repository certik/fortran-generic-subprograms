! TEST-RULE: C718
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C718|kind.*rank one|rank-one.*kind
! TEST-ERROR-PHASE: compile
module reject_kind_rank_two_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer(reshape([kind(0)], [1, 1])) :: x
  end subroutine
end module
