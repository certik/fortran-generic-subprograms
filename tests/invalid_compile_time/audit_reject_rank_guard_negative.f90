! TEST-RULE: C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C875|rank.*nonnegative|negative.*rank
! TEST-ERROR-PHASE: compile
module audit_reject_rank_guard_negative_m
  implicit none
contains
  generic subroutine reject_negative(x)
    integer, rank(0:1), intent(in) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (-1)
      continue
    end select
  end subroutine
end module
