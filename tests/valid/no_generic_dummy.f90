! A generic subprogram with no generic dummy defines one unnamed specific.
! The name is generic (15.6.2.4 NOTE 7). RANK(0) is not a generic rank.
module no_generic_dummy_m
  implicit none
contains
  generic function square(x)
    real, intent(in), rank(0) :: x
    typeof(x), rank(rank(x)) :: square
    square = x**2
  end function
end module

program no_generic_dummy_p
  use no_generic_dummy_m
  implicit none
  if (square(3.0) /= 9.0) error stop "square"
  if (square(-2.0) /= 4.0) error stop "square negative"
end program
