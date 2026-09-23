! TEST-RULE: R712 R713 R714 C719 C721 C722 C723 15.6.2.4
! TEST-REQUIRES: int32 int64
! TEST-PASS: parameterized_derived
! Kind-parameter arrays multiply; a scalar kind does not. Length parameters
! are assumed (7.3.2.2 NOTE 2, C722, C723). Requires kind(0.0) /= kind(0.0d0).
module parameterized_derived_m
  implicit none
  type t(k1, k2, n)
    integer, kind :: k1, k2
    integer, len :: n
    real(k1) :: value(k2, n)
  end type
  type u(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine fill(x)
    type(t([kind(0.0), kind(0.0d0)], k2=[1, 2, 4, 8], n=*)), intent(inout) :: x
    x%value = real(x%k2, kind(x%value))
  end subroutine

  generic subroutine fill_u(x)
    use, intrinsic :: iso_fortran_env, only: int32, int64
    type(u(k=[int32, int64], n=*)), intent(inout) :: x
    x%v = int(x%n, kind(x%v))
  end subroutine

  generic subroutine check(x, k1, k2, n)
    type(t([kind(0.0), kind(0.0d0)], k2=[1, 2, 4, 8], n=*)), intent(inout) :: x
    integer, intent(in) :: k1, k2, n
    call fill(x)
    if (x%k1 /= k1) error stop "k1"
    if (x%k2 /= k2) error stop "k2"
    if (x%n /= n) error stop "n"
    if (any(abs(x%value - real(k2, kind(x%value))) /= 0.0)) error stop "value"
  end subroutine
end module

program parameterized_derived_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use parameterized_derived_m
  implicit none
  integer, parameter :: ks = kind(0.0), kd = kind(0.0d0)
  type(t(k1=ks, k2=1, n=3)) :: a1
  type(t(k1=ks, k2=2, n=3)) :: a2
  type(t(k1=ks, k2=4, n=2)) :: a4
  type(t(k1=ks, k2=8, n=1)) :: a8
  type(t(k1=kd, k2=1, n=3)) :: b1
  type(t(k1=kd, k2=2, n=3)) :: b2
  type(t(k1=kd, k2=4, n=2)) :: b4
  type(t(k1=kd, k2=8, n=1)) :: b8
  type(u(k=int32, n=4)) :: u32
  type(u(k=int64, n=5)) :: u64
  if (ks == kd) error stop "need distinct default real and double precision"
  if (int32 < 0 .or. int64 < 0) error stop "need int32 and int64"
  call check(a1, ks, 1, 3)
  call check(a2, ks, 2, 3)
  call check(a4, ks, 4, 2)
  call check(a8, ks, 8, 1)
  call check(b1, kd, 1, 3)
  call check(b2, kd, 2, 3)
  call check(b4, kd, 4, 2)
  call check(b8, kd, 8, 1)
  call fill_u(u32)
  call fill_u(u64)
  if (kind(u32%v) /= int32 .or. any(u32%v /= 4_int32)) error stop "u int32"
  if (kind(u64%v) /= int64 .or. any(u64%v /= 5_int64)) error stop "u int64"
  print '(a)', 'TEST-PASS: parameterized_derived'
end program
