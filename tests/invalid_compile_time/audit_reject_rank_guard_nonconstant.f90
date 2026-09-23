! TEST-RULE: R832 R833 10.1.12
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: rank.*constant|constant expression.*RANK|nonconstant.*rank
! TEST-ERROR-PHASE: compile
module audit_reject_rank_guard_nonconstant_m
  implicit none
contains
  generic subroutine reject_nonconstant(x, runtime_rank)
    integer, rank(0:1), intent(in) :: x
    integer, intent(in) :: runtime_rank
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (runtime_rank)
      continue
    end select
  end subroutine
end module
