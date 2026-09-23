! TEST-RULE: R832 R833
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: rank.*scalar|scalar.*constant.*RANK|array.*rank guard
! TEST-ERROR-PHASE: compile
module audit_reject_rank_guard_nonscalar_m
  implicit none
  integer, parameter :: rank_values(2) = [0, 1]
contains
  generic subroutine reject_nonscalar(x)
    integer, rank(0:1), intent(in) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (rank_values)
      continue
    end select
  end subroutine
end module
