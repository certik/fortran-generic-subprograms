! Invalid: C1160. A length parameter in DECLARED TYPE IS is assumed (*),
! not deferred (:).
module pdt_guard_colon_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
  type :: u(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
    type(u(k=[int32, int64], n=:)), allocatable :: x
    select generic type (x)
    declared type is (u(k=int32, n=:))
      allocate(u(int32, 1) :: x)
    end select
  end subroutine
end module
