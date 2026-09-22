! Invalid: C1537 and 10.2.2.4. The generic name is not a specific procedure,
! so it is not a procedure-pointer target.
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
  procedure(square), pointer :: q
  q => square
end program
