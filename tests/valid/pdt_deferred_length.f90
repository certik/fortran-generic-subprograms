! TEST-RULE: R712 R713 R714 C717 C722 C723 7.2 15.6.2.4
! TEST-REQUIRES: int32 int64
! A deferred length parameter is written "n=:" (C722). This settled core
! exercises deferred-length allocatable dummies without an assumed-length
! generic type guard; that interpretation-dependent guard is isolated in
! draft_interpretations/valid.
module pdt_deferred_length_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
  type :: u(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine fill(x)
    type(u(k=[int32, int64], n=:)), allocatable, intent(inout) :: x
    x%v = int(x%n, kind=kind(x%v))
  end subroutine
end module

program pdt_deferred_length_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use pdt_deferred_length_m
  implicit none
  type(u(k=int32, n=:)), allocatable :: a
  type(u(k=int64, n=:)), allocatable :: b
  if (int32 < 0 .or. int64 < 0) error stop "need int32 and int64"
  allocate(u(int32, 4) :: a)
  allocate(u(int64, 5) :: b)
  call fill(a)
  call fill(b)
  if (.not. allocated(a)) error stop "int32 allocated"
  if (.not. allocated(b)) error stop "int64 allocated"
  if (a%k /= int32 .or. a%n /= 4) error stop "int32 params"
  if (b%k /= int64 .or. b%n /= 5) error stop "int64 params"
  if (any(a%v /= 4_int32)) error stop "int32 value"
  if (any(b%v /= 5_int64)) error stop "int64 value"
end program
