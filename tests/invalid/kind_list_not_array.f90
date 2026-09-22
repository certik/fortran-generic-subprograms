! Invalid syntax. The kind set is one rank-one expression, written
! INTEGER([INT32, INT64]), not INTEGER(INT32, INT64).
module kind_list_not_array_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
contains
  generic subroutine s(x)
    integer(int32, int64) :: x
  end subroutine
end module
