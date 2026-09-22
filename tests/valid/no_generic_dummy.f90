! TEST-RULE: C877 15.6.2.4 NOTE7
! A generic subprogram with no generic dummy defines one unnamed specific.
! The name is generic (15.6.2.4 NOTE 7). RANK(0) is not a generic rank.
! The result is a scalar declared without a RANK clause. C877 allows a
! RANK clause only on a named constant, a dummy, or an allocatable or
! pointer, so NOTE 7's RANK(RANK(x)) on the result is not used.
module no_generic_dummy_m
  implicit none
contains
  generic function square(x)
    real, intent(in), rank(0) :: x
    real :: square
    square = x**2
  end function

  generic integer function answer()
    answer = 42
  end function
end module

program no_generic_dummy_p
  use no_generic_dummy_m
  implicit none
  if (square(3.0) /= 9.0) error stop "square"
  if (square(-2.0) /= 4.0) error stop "square negative"
  if (answer() /= 42) error stop "no-argument generic"
end program
