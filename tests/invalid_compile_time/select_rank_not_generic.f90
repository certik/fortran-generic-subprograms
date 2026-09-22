! TEST-RULE: C1155
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1155|not.*rank-generic|selector.*rank-generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1155. RANK(1) is a single rank-spec, so x is not rank-generic.
module select_rank_not_generic_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(1) :: x
    ! TEST-ERROR-HERE
    select generic rank (x)
    rank (1)
      x = 1
    end select
  end subroutine
end module
