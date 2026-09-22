! TEST-RULE: C1518 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1518|generic name.*procedure interface|interface-name.*specific
! TEST-ERROR-PHASE: compile
module reject_generic_procedure_interface_m
  implicit none
contains
  generic real function square(x)
    real, intent(in) :: x
    square = x**2
  end function
end module

program reject_generic_procedure_interface_p
  use reject_generic_procedure_interface_m
  implicit none
  ! TEST-ERROR-HERE
  procedure(square), pointer :: p
end program
