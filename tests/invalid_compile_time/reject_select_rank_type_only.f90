! TEST-RULE: C1155
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1155|selector.*rank-generic dummy|not.*rank-generic
! TEST-ERROR-PHASE: compile
module reject_select_rank_type_only_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    ! TEST-ERROR-HERE
    select generic rank (x)
    rank (0)
      x = 0
    end select
  end subroutine
end module
