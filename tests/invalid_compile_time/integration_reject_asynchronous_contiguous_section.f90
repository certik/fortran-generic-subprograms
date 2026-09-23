! TEST-RULE: C1551 15.5.2.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1551|(ASYNCHRONOUS|asynchronous).*(contiguous|CONTIGUOUS)|(contiguous|CONTIGUOUS).*(ASYNCHRONOUS|asynchronous)|not simply contiguous|no (matching )?specific (function|procedure|subroutine)|matches the actual arguments
! TEST-ERROR-PHASE: compile
! The generated rank-one specific has an ASYNCHRONOUS CONTIGUOUS
! assumed-shape dummy, so a noncontiguous ASYNCHRONOUS section cannot
! correspond to it (C1551). Without CONTIGUOUS the same call is valid
! (valid/audit_integration_attribute_preservation.f90). The ordinary
! expansion is reported by gfortran and flang as a call with no matching
! specific, which is accepted when located at the marked call.
module integration_reject_asynchronous_contiguous_section_m
  implicit none
contains
  generic subroutine consume(x)
    type(integer, real), asynchronous, contiguous, intent(inout), rank(1:2) :: x
    x = 0
  end subroutine
end module

program integration_reject_asynchronous_contiguous_section_p
  use integration_reject_asynchronous_contiguous_section_m
  implicit none
  integer, asynchronous :: values(6)
  values = 1
  ! TEST-ERROR-HERE
  call consume(values(1:6:2))
end program
