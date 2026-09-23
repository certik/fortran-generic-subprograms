! TEST-RULE: R707 R708 C718 15.6.2.4
! TEST-REQUIRES: real32 real64
! TEST-PASS: real_complex_kinds
! REAL(REAL_KINDS) and COMPLEX([REAL32, REAL64]) (7.3.2.2).
! Every real kind is a specific of twice; the program also exercises two
! named, processor-optional kinds declared in TEST-REQUIRES.
module real_complex_kinds_m
  use, intrinsic :: iso_fortran_env, only: real32, real64, real_kinds
  implicit none
contains
  generic function twice(x) result(y)
    real(real_kinds), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function

  generic subroutine check_real(x)
    real(real_kinds), intent(in) :: x
    if (twice(x) /= x + x) error stop "check twice"
    if (kind(twice(x)) /= kind(x)) error stop "check real kind"
  end subroutine

  generic function add1(x) result(y)
    complex([real32, real64]), intent(in) :: x
    typeof(x) :: y
    y = x + cmplx(1, 0, kind=kind(x))
  end function
end module

program real_complex_kinds_p
  use, intrinsic :: iso_fortran_env, only: real32, real64
  use real_complex_kinds_m
  implicit none
  integer, parameter :: p6 = selected_real_kind(6)
  complex(real32) :: c32
  complex(real64) :: c64
  if (real32 < 0 .or. real64 < 0 .or. real32 == real64) &
    error stop "need distinct real32 and real64"
  if (p6 < 0) error stop "selected_real_kind(6)"
  if (twice(1.0_real32) /= 2.0_real32) error stop "real32"
  if (twice(1.0_real64) /= 2.0_real64) error stop "real64"
  if (twice(1.0) /= 2.0) error stop "default real"
  if (twice(1.0_p6) /= 2.0_p6) error stop "precision 6"
  if (kind(twice(1.0_real64)) /= real64) error stop "real kind"
  call check_real(1.0_real32)
  call check_real(1.0_real64)
  call check_real(1.0)
  call check_real(1.0_p6)
  c32 = cmplx(2.0_real32, 3.0_real32, kind=real32)
  c64 = cmplx(2.0_real64, 3.0_real64, kind=real64)
  if (add1(c32) /= cmplx(3.0_real32, 3.0_real32, kind=real32)) error stop "complex32"
  if (add1(c64) /= cmplx(3.0_real64, 3.0_real64, kind=real64)) error stop "complex64"
  if (kind(add1(c64)) /= real64) error stop "complex kind"
  print '(a)', 'TEST-PASS: real_complex_kinds'
end program
