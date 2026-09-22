! TEST-RULE: C1158
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1158|END SELECT.*construct name|missing.*construct name
! TEST-ERROR-PHASE: compile
module reject_rank_end_name_missing_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    named: select generic rank (x)
    rank default
      continue
    ! TEST-ERROR-HERE
    end select
  end subroutine
end module
