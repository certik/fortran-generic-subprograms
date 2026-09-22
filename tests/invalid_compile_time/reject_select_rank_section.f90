! TEST-RULE: C1155
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1155|selector.*name.*rank-generic|array section.*SELECT GENERIC RANK
! TEST-ERROR-PHASE: compile
module reject_select_rank_section_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(1, 1) :: x
    ! TEST-ERROR-HERE
    select generic rank (x(:))
    rank (1)
      x = 0
    end select
  end subroutine
end module
