! TEST-RULE: C801
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C801|generic RANK.*generic subprogram|outside.*generic subprogram
! TEST-ERROR-PHASE: compile
module reject_rank_outside_generic_m
  implicit none
contains
  subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(0:1) :: x
  end subroutine
end module
