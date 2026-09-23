! TEST-RULE: C872 8.5.16 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C872|PROTECTED_TARGET.*(dummy|argument)|(dummy|argument).*PROTECTED_TARGET|protected target.*(dummy|argument)
! TEST-ERROR-PHASE: compile
! The actual selects the integer scalar pointer specific, whose pointer dummy
! lacks PROTECTED_TARGET, so the PROTECTED_TARGET actual cannot correspond
! to it (C872).
module integration_reject_protected_target_dummy_m
  implicit none
contains
  generic function inspect(view) result(total)
    type(integer, real), pointer, intent(in), rank(0:1) :: view
    real :: total
    total = real(sum([view]))
  end function
end module

program integration_reject_protected_target_dummy_p
  use integration_reject_protected_target_dummy_m
  implicit none
  integer, pointer, protected_target :: shared
  allocate(shared, source=3)
  ! TEST-ERROR-HERE
  if (inspect(shared) /= 3.0) error stop "unreachable"
end program
