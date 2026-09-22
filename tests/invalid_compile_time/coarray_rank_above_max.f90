! Invalid: C875. For corank 1 the upper bound is MAX_RANK(1), not one more.
module coarray_rank_above_max_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:max_rank(1)+1) :: x[*]
  end subroutine
end module
