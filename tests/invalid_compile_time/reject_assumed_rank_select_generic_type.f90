! TEST-RULE: C845
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C845|assumed-rank.*SELECT GENERIC TYPE|assumed-rank.*selector
! TEST-ERROR-PHASE: compile
module reject_assumed_rank_select_generic_type_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x(..)
    ! TEST-ERROR-HERE
    select generic type (x)
    declared type default
      continue
    end select
  end subroutine
end module
