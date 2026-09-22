! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|generic dummy.*OPTIONAL|OPTIONAL.*generic dummy
! TEST-ERROR-PHASE: compile
module reject_generic_optional_separate_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    ! TEST-ERROR-HERE
    optional :: x
  end subroutine
end module
