! TEST-RULE: C1157
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1157|rank guard.*construct name|construct name.*SELECT GENERIC RANK
! TEST-ERROR-PHASE: compile
module reject_rank_guard_name_without_select_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (0) named
      x = 0
    end select
  end subroutine
end module
