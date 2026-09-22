! TEST-RULE: C15135
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15135|elemental.*dummy.*POINTER|POINTER.*elemental
! TEST-ERROR-PHASE: compile
module reject_elemental_pointer_dummy_m
  implicit none
contains
  elemental generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(integer, real), pointer, intent(in) :: x
  end subroutine
end module
