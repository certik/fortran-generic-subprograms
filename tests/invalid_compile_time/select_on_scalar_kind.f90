! Invalid: C1159. INTEGER(INT32) is an ordinary scalar kind selector, not a
! generic-intrinsic-type-spec. The dummy is not type-generic.
module select_on_scalar_kind_m
  use, intrinsic :: iso_fortran_env, only: int32
  implicit none
contains
  generic subroutine s(x)
    integer(int32) :: x
    select generic type (x)
    declared type is (integer(int32))
      x = 1_int32
    end select
  end subroutine
end module
