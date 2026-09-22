! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|generic.*declaration.*dummy|local.*generic RANK
! TEST-ERROR-PHASE: compile
module reject_rank_generic_local_m
  implicit none
contains
  generic subroutine s(x)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    integer, allocatable, rank(0:1) :: local
  end subroutine
end module
