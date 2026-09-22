! TEST-RULE: 19.2.3.6 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C_FUNLOC.*procedure|generic name.*C_FUNLOC|argument.*not.*procedure
! TEST-ERROR-PHASE: compile
module reject_generic_c_funloc_m
  implicit none
contains
  generic real function square(x)
    real, intent(in) :: x
    square = x**2
  end function
end module

program reject_generic_c_funloc_p
  use, intrinsic :: iso_c_binding, only: c_funloc, c_funptr
  use reject_generic_c_funloc_m
  implicit none
  type(c_funptr) :: address
  ! TEST-ERROR-HERE
  address = c_funloc(square)
end program
