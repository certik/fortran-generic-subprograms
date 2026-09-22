! TEST-RULE: C876
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C876|generic RANK.*array-spec|assumed-size.*generic rank
! TEST-ERROR-PHASE: compile
module reject_rank_assumed_size_array_spec_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(0:1) :: x(*)
  end subroutine
end module
