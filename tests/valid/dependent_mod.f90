! TEST-RULE: R704 R708 C718 7.3.2.1 15.6.2.4
! TEST-REQUIRES: real32 real64
! TEST-PASS: dependent_mod
! A dependent second argument does not add combinations, so MOD is legal.
! A non-generic assumed-shape array can still follow the generic type.
module dependent_mod_m
  use, intrinsic :: iso_fortran_env, only: real32, real64
  implicit none
contains
  generic function modulo_wrap(x, y) result(z)
    real([real32, real64]), intent(in) :: x
    typeof(x), intent(in) :: y
    typeof(x) :: z
    z = mod(x, y)
  end function

  generic function scaled_sum(s, v) result(y)
    type(integer, real), intent(in) :: s
    typeof(s), intent(in) :: v(:)
    typeof(s) :: y
    y = s * sum(v)
  end function
end module

program dependent_mod_p
  use, intrinsic :: iso_fortran_env, only: real32, real64
  use dependent_mod_m
  implicit none
  if (real32 < 0 .or. real64 < 0) error stop "need real32 and real64"
  if (modulo_wrap(5.0_real32, 3.0_real32) /= 2.0_real32) error stop "mod real32"
  if (modulo_wrap(5.0_real64, 3.0_real64) /= 2.0_real64) error stop "mod real64"
  if (scaled_sum(2, [1, 2, 3]) /= 12) error stop "scaled integer"
  if (scaled_sum(1.5, [1.0, 2.0]) /= 4.5) error stop "scaled real"
  print '(a)', 'TEST-PASS: dependent_mod'
end program
