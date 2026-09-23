! TEST-RULE: R832 R833
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: rank.*integer|integer.*constant.*RANK|noninteger.*rank
! TEST-ERROR-PHASE: compile
module audit_reject_rank_guard_noninteger_m
  implicit none
contains
  generic subroutine reject_noninteger(x)
    integer, rank(0:1), intent(in) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (0.0)
      continue
    end select
  end subroutine
end module
