! Invalid: C1161. The same type and kind type parameters in two guards.
! The length parameter does not distinguish them.
module pdt_guard_duplicate_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
  type :: u(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
    type(u(k=[int32, int64], n=*)), intent(inout) :: x
    select generic type (x)
    declared type is (u(k=int32, n=*))
      x%v = 1_int32
    declared type is (u(k=int32, n=*))
      x%v = 2_int32
    end select
  end subroutine
end module
