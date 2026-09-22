! TEST-RULE: C804
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C804|character length.*(asterisk|colon)|explicit.*length.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C804. A *char-length on a generic declaration is * or :, not an
! explicit length.
module char_length_explicit_override_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    character(len=*, kind=[kind('a')]) :: x*10
  end subroutine
end module
