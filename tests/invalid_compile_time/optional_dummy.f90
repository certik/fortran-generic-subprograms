! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|generic dummy.*OPTIONAL|OPTIONAL.*generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C802. A generic dummy shall not have the OPTIONAL attribute.
module optional_dummy_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(integer, real), optional :: x
  end subroutine
end module
