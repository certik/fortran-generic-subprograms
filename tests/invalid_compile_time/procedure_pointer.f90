! TEST-RULE: C1034 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1034|procedure pointer.*generic|generic name.*pointer target
! TEST-ERROR-PHASE: compile
! Invalid: C1034. The generic name is not a specific procedure, so it is not
! a procedure-pointer target. The pointer itself uses an independent,
! otherwise-valid explicit interface.
module procedure_pointer_m
  implicit none
contains
  generic function square(x)
    real, intent(in) :: x
    real :: square
    square = x**2
  end function
end module

program procedure_pointer_p
  use procedure_pointer_m
  implicit none
  abstract interface
    real function unary(x)
      real, intent(in) :: x
    end function
  end interface
  procedure(unary), pointer :: q
  ! TEST-ERROR-HERE
  q => square
end program
