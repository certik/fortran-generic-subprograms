! TEST-RULE: C866 8.5.16 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C866|PROTECTED_TARGET.*(definition|defin|assign|modif)|(definition|defin|assign).*PROTECTED_TARGET|protected target.*(defin|assign)
! TEST-ERROR-PHASE: compile
! Every generated specific keeps PROTECTED_TARGET on its pointer dummy, so
! the target cannot be defined through it (C866); ALLOCATE with SOURCE=,
! reading, and pointer assignment remain valid
! (valid/audit_integration_attribute_preservation.f90).
module integration_reject_protected_target_definition_m
  implicit none
contains
  generic subroutine overwrite(view)
    type(integer, real), pointer, protected_target, intent(in), rank(0:1) :: view
    ! TEST-ERROR-HERE
    view = 0
  end subroutine
end module
