! TEST-RULE: 11.1.10.2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: rank.*matches.*more than one|multiple.*SELECT GENERIC.*block|overlapping.*rank
! TEST-ERROR-PHASE: compile
! Nonconforming: rank 2 matches both guards, but 11.1.10.2 says each specific
! contains at most one block. There is no C1166-style constraint for this
! construct; the requirement is the "at most one block" rule.
module overlapping_rank_guards_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:3) :: x
    select generic rank (x)
    rank (0:2)
      x = 1
    ! TEST-ERROR-HERE
    rank (2:3)
      x = 2
    end select
  end subroutine
end module
