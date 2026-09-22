! A generic subprogram may have the name of an intrinsic. A reference that
! matches one of its specifics calls that specific. A reference that matches
! none of them, and matches the intrinsic, calls the intrinsic
! (15.4.3.4.5 p8, 15.5.5.2 p5).
module extend_intrinsic_m
  implicit none
contains
  generic function sin(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function
end module

program extend_intrinsic_p
  use extend_intrinsic_m
  implicit none
  complex :: z
  if (sin(3) /= 6) error stop "integer specific"
  if (sin(1.5) /= 3.0) error stop "real specific, not intrinsic sin"
  z = sin((0.0, 1.0))
  if (aimag(z) == 0.0) error stop "complex uses intrinsic sin"
end program
