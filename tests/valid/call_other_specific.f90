! One specific may call a different specific of the same generic name.
! The integer block is not part of the real specific, so this is not recursive.
module call_other_specific_m
  implicit none
contains
  generic function widen(x) result(y)
    type(integer, real), intent(in) :: x
    real :: y
    select generic type (x)
    declared type is (integer)
      y = widen(real(x))
    declared type is (real)
      y = x
    end select
  end function
end module

program call_other_specific_p
  use call_other_specific_m
  implicit none
  if (widen(3) /= 3.0) error stop "integer calls real specific"
  if (widen(1.5) /= 1.5) error stop "real specific"
end program
