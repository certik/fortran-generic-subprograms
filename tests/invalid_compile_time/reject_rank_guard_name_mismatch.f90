! TEST-RULE: C1157
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1157|rank guard.*construct name|construct name.*mismatch
! TEST-ERROR-PHASE: compile
module reject_rank_guard_name_mismatch_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    expected: select generic rank (x)
    ! TEST-ERROR-HERE
    rank (0) other
      x = 0
    end select expected
  end subroutine
end module
