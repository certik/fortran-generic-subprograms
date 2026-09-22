! TEST-RULE: C725
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C725|assumed-type.*SELECT GENERIC RANK|assumed-type.*selector
! TEST-ERROR-PHASE: compile
module reject_assumed_type_select_generic_rank_m
  implicit none
contains
  generic subroutine s(x)
    type(*), rank(0:1) :: x
    ! TEST-ERROR-HERE
    select generic rank (x)
    rank default
      continue
    end select
  end subroutine
end module
