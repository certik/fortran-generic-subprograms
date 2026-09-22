! TEST-RULE: C15135
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15135|elemental.*dummy.*coarray|coarray.*elemental
! TEST-ERROR-PHASE: compile
module reject_elemental_coarray_dummy_m
  implicit none
contains
  elemental generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, intent(in) :: x[*]
  end subroutine
end module
