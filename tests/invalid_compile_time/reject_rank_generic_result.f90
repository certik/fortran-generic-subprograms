! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|generic.*declaration.*dummy|function result.*generic RANK
! TEST-ERROR-PHASE: compile
module reject_rank_generic_result_m
  implicit none
contains
  generic function f(x) result(y)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    integer, allocatable, rank(0:1) :: y
  end function
end module
