! REAL([REAL32, REAL64]) and COMPLEX([REAL32, REAL64]) (7.3.2.2).
! Assumes REAL32 and REAL64 exist and differ.
module real_complex_kinds_m
  use, intrinsic :: iso_fortran_env, only: real32, real64
  implicit none
contains
  generic function twice(x) result(y)
    real([real32, real64]), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function

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
  complex(real32) :: c32
  complex(real64) :: c64
  if (real32 <= 0 .or. real64 <= 0 .or. real32 == real64) &
    error stop "need distinct real32 and real64"
  if (twice(1.0_real32) /= 2.0_real32) error stop "real32"
  if (twice(1.0_real64) /= 2.0_real64) error stop "real64"
  if (kind(twice(1.0_real64)) /= real64) error stop "real kind"
  c32 = cmplx(2.0_real32, 3.0_real32, kind=real32)
  c64 = cmplx(2.0_real64, 3.0_real64, kind=real64)
  if (add1(c32) /= cmplx(3.0_real32, 3.0_real32, kind=real32)) error stop "complex32"
  if (add1(c64) /= cmplx(3.0_real64, 3.0_real64, kind=real64)) error stop "complex64"
  if (kind(add1(c64)) /= real64) error stop "complex kind"
end program
