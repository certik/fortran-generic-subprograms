! TEST-RULE: 11.1.10.2 11.2.1 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: branch.*(SELECT GENERIC|construct|block)|label.*(block|construct)|target.*inside
! TEST-ERROR-PHASE: compile
! RANK(0:0) is generic but creates one specific, whose target block is
! retained; this isolates illegal entry from any missing-label diagnostic.
module audit_reject_branch_into_rank_block_m
  implicit none
contains
  generic subroutine reject_branch_into(x)
    integer, rank(0:0), intent(inout) :: x
    ! TEST-ERROR-HERE
    go to 100
    selected: select generic rank (x)
    rank (0) selected
    ! TEST-ERROR-HERE
100   continue
      x = 0
    end select selected
  end subroutine
end module
