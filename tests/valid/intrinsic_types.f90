! TEST-RULE: R705 R706 C716 11.1.11 15.6.2.4
! TYPE(INTEGER, REAL, COMPLEX). Unselected blocks are deleted: CONJG is only
! in the complex specific, so every retained block is valid for its specific.
module intrinsic_types_m
  implicit none
contains
  generic function classify(x) result(y)
    type(integer, real, complex), intent(in) :: x
    integer :: y
    select generic type (x)
    declared type is (integer)
      y = 1
    declared type is (real)
      y = 2
    declared type is (complex)
      y = 3
    end select
  end function

  generic function mag(x) result(y)
    type(real, complex), intent(in) :: x
    real(kind(x)) :: y
    select generic type (x)
    declared type is (real)
      y = abs(x)
    declared type is (complex)
      y = abs(conjg(x))
    end select
  end function
end module

program intrinsic_types_p
  use intrinsic_types_m
  implicit none
  complex :: z
  z = (1.0, 2.0)
  if (classify(3) /= 1) error stop "classify integer"
  if (classify(3.0) /= 2) error stop "classify real"
  if (classify(z) /= 3) error stop "classify complex"
  if (mag(3.0) /= 3.0) error stop "mag real"
  if (mag(z) /= abs(conjg(z))) error stop "mag complex"
end program
