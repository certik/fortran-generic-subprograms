! TEST-RULE: C15115 15.6.2.4 15.7
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15115|(VOLATILE|volatile).*pure|pure.*(VOLATILE|volatile)
! TEST-ERROR-PHASE: compile
! VOLATILE is preserved in every generated specific, so a designator of the
! VOLATILE generic dummy cannot appear in the pure specifics (C15115). The
! impure counterpart is valid/audit_integration_attribute_preservation.f90.
! gfortran and flang report the ordinary expansion at the VOLATILE
! declaration, so that statement is marked as well as the designator.
module integration_reject_volatile_pure_generic_m
  implicit none
contains
  pure generic subroutine adjust(x)
    ! TEST-ERROR-HERE
    type(integer, real), volatile, intent(inout), rank(0:1) :: x
    ! TEST-ERROR-HERE
    x = x + 1
  end subroutine
end module
