! TEST-RULE: R1152 R832 R833
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: syntax.*RANK|invalid.*rank range|rank range.*missing|expected.*(expression|integer)
! TEST-ERROR-PHASE: compile
module audit_reject_rank_guard_open_range_m
  implicit none
contains
  generic subroutine reject_open_range(x)
    integer, rank(0:1), intent(in) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (0:)
      continue
    end select
  end subroutine
end module
