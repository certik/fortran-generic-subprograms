! TEST-RULE: C714
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C714|OPTIONAL.*assumed.*type parameter|TYPEOF.*optional.*assumed
! TEST-ERROR-PHASE: compile
module audit_reject_typeof_optional_assumed_m
  implicit none
contains
  generic subroutine reject_optional_assumed(tag, text)
    type(integer, real), intent(in) :: tag
    ! Scalar KIND keeps TEXT ordinary, isolating C714 from C802.
    character(len=*, kind=kind('a')), intent(in), optional :: text
    ! TEST-ERROR-HERE
    typeof(text) :: copy
  end subroutine
end module
