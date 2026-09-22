! RANK(0:MAX_RANK()) is every non-coarray rank. The body is legal for each
! of them (8.5.17, ISO_FORTRAN_ENV MAX_RANK).
module full_rank_range_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
contains
  generic function rnk(x) result(n)
    integer, intent(in), rank(0:max_rank()) :: x
    integer :: n
    n = rank(x)
  end function
end module

program full_rank_range_p
  use, intrinsic :: iso_fortran_env, only: max_rank
  use full_rank_range_m
  implicit none
  integer :: r1(2), r2(1, 2), r7(1, 1, 1, 1, 1, 1, 2)
  if (max_rank() < 7) error stop "processor rank below 7"
  if (rnk(0) /= 0) error stop "rank 0"
  if (rnk(r1) /= 1) error stop "rank 1"
  if (rnk(r2) /= 2) error stop "rank 2"
  if (rnk(r7) /= 7) error stop "rank 7"
end program
