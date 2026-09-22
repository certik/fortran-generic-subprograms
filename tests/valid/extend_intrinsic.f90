! TEST-RULE: 15.4.3.4.5 15.5.5.2 15.6.2.4
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

  generic subroutine random_number(x)
    integer, intent(out), rank(0:1) :: x
    x = 42
  end subroutine

  ! The intrinsic RANDOM_SEED is a subroutine, so it is inaccessible by this
  ! local generic function name. The generated function remains callable.
  generic integer function random_seed()
    random_seed = 77
  end function
end module

program extend_intrinsic_p
  use extend_intrinsic_m
  implicit none
  complex :: z
  real :: harvest(4)
  integer :: n, values(3)
  if (sin(3) /= 6) error stop "integer specific"
  if (sin(1.5) /= 3.0) error stop "real specific, not intrinsic sin"
  z = sin((0.0, 1.0))
  if (aimag(z) == 0.0) error stop "complex uses intrinsic sin"
  call random_number(n)
  call random_number(values)
  if (n /= 42 .or. any(values /= 42)) error stop "subroutine specifics"
  call random_number(harvest)
  if (any(harvest < 0.0) .or. any(harvest >= 1.0)) then
    error stop "intrinsic subroutine fallback"
  end if
  if (random_seed() /= 77) error stop "function-subroutine distinction"
end program
