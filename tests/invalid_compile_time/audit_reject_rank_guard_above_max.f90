! TEST-RULE: R1152 R832 R833 C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C875|rank.*maximum|maximum.*rank|rank.*out of range
! TEST-ERROR-PHASE: compile
! R1152 reuses rank-spec-list (R832/R833), so C875 applies.  The selector X
! supplies the noncoarray object-name/corank context for MAX_RANK().
module audit_reject_rank_guard_above_max_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
contains
  generic subroutine reject_above_max(x)
    integer, rank(0:1), intent(in) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (max_rank()+1)
      continue
    end select
  end subroutine
end module
