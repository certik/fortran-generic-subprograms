! A generic rank and a corank together have to be legal for every rank in
! the set. RANK(0:MAX_RANK(1)) is the portable upper bound for corank 1
! (C826, C875, MAX_RANK).
program coarray_rank_p
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
  integer :: scalar[*]
  integer :: vector(2)[*]
  integer :: high(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  if (max_rank(1) < 14) error stop "corank-1 rank below 14"
  scalar = 0
  vector = 0
  high = 0
  if (rnk(scalar) /= 0) error stop "scalar coarray"
  if (rnk(vector) /= 1) error stop "rank-1 coarray"
  if (rnk(high) /= 14) error stop "rank-14 coarray"
contains
  generic function rnk(x) result(n)
    integer, intent(in), rank(0:max_rank(1)) :: x[*]
    integer :: n
    n = rank(x)
  end function
end program
