! TEST-RULE: C876
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C876|generic RANK.*array-spec|array specification.*generic rank
! TEST-ERROR-PHASE: compile
! Invalid: C876. An entity with a generic RANK clause has no array-spec.
module array_spec_on_generic_rank_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(1:2) :: x(:)
  end subroutine
end module
