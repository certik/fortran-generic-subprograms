! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|single entity|one dummy.*generic declaration
! TEST-ERROR-PHASE: compile
! Invalid: C802. A generic type declaration names exactly one dummy.
module two_objects_m
  implicit none
contains
  generic subroutine s(x, y)
    ! TEST-ERROR-HERE
    type(integer, real), intent(in) :: x, y
  end subroutine
end module
