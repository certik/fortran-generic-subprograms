! A deferred length parameter is written "n=:" (C722). The type guard still
! spells that length as assumed, "n=*" (C1160). Kind parameters in the guard
! are written in full.
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
    type(u(k=[int32, int64], n=:)), allocatable, intent(out) :: x
    select generic type (x)
    declared type is (u(k=int32, n=*))
      allocate(u(int32, 4) :: x)
      x%v = 4_int32
    declared type is (u(k=int64, n=*))
      allocate(u(int64, 5) :: x)
      x%v = 5_int64
    end select
  end subroutine
end module

program pdt_deferred_length_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use pdt_deferred_length_m
  implicit none
  type(u(k=int32, n=:)), allocatable :: a
  type(u(k=int64, n=:)), allocatable :: b
  if (int32 <= 0 .or. int64 <= 0) error stop "need int32 and int64"
  call fill(a)
  call fill(b)
  if (.not. allocated(a)) error stop "int32 allocated"
  if (.not. allocated(b)) error stop "int64 allocated"
  if (a%k /= int32 .or. a%n /= 4) error stop "int32 params"
  if (b%k /= int64 .or. b%n /= 5) error stop "int64 params"
  if (any(a%v /= 4_int32)) error stop "int32 value"
  if (any(b%v /= 5_int64)) error stop "int64 value"
end program
