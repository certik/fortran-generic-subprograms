! TEST-RULE: 4.2(3) 4.2(6) C1184 11.1.10.2 15.6.2.4p2 20.1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1184|branch.*(SELECT GENERIC|block)|target.*(deleted|other block)|label.*(not|never).*defined|undefined.*label
! TEST-ERROR-PHASE: compile
! In the rank-zero specific the target block, and therefore label 200, is
! deleted.  The retained GO TO then violates C1184 and Clause 20 label scope.
module audit_reject_branch_between_rank_blocks_m
  implicit none
contains
  generic subroutine reject_branch_between(x)
    integer, rank(0:1), intent(inout) :: x
    select generic rank (x)
    rank (0)
      ! TEST-ERROR-HERE
      go to 200
    rank (1)
    ! TEST-ERROR-HERE
200   continue
      x = 1
    end select
  end subroutine
end module
