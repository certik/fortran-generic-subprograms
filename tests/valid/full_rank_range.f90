! RANK(0:MAX_RANK()) is every non-coarray rank (8.5.17). Ranks 0 through 15
! are executed. Fifteen is the minimum value of MAX_RANK(). A processor with
! a higher maximum still has those specifics; they have to compile, and
! rank_above_max rejects MAX_RANK()+1. A source file cannot declare an array
! whose rank is a processor-dependent MAX_RANK() above 15.
module full_rank_range_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
contains
  generic function rnk(x) result(n)
    integer, intent(in), rank(0:max_rank()) :: x
    integer :: n
    n = rank(x)
    select generic rank (x)
    rank (0)
      if (n /= 0) error stop "scalar block"
    rank default
      if (size(x) /= 2) error stop "extent"
    end select
  end function
end module

program full_rank_range_p
  use, intrinsic :: iso_fortran_env, only: max_rank
  use full_rank_range_m
  implicit none
  integer :: r1(2)
  integer :: r2(1, 2)
  integer :: r3(1, 1, 2)
  integer :: r4(1, 1, 1, 2)
  integer :: r5(1, 1, 1, 1, 2)
  integer :: r6(1, 1, 1, 1, 1, 2)
  integer :: r7(1, 1, 1, 1, 1, 1, 2)
  integer :: r8(1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r9(1, 1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r10(1, 1, 1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r11(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r12(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r13(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r14(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)
  integer :: r15(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)
  if (max_rank() < 15) error stop "processor rank below 15"
  if (rnk(0) /= 0) error stop "rank 0"
  if (rnk(r1) /= 1) error stop "rank 1"
  if (rnk(r2) /= 2) error stop "rank 2"
  if (rnk(r3) /= 3) error stop "rank 3"
  if (rnk(r4) /= 4) error stop "rank 4"
  if (rnk(r5) /= 5) error stop "rank 5"
  if (rnk(r6) /= 6) error stop "rank 6"
  if (rnk(r7) /= 7) error stop "rank 7"
  if (rnk(r8) /= 8) error stop "rank 8"
  if (rnk(r9) /= 9) error stop "rank 9"
  if (rnk(r10) /= 10) error stop "rank 10"
  if (rnk(r11) /= 11) error stop "rank 11"
  if (rnk(r12) /= 12) error stop "rank 12"
  if (rnk(r13) /= 13) error stop "rank 13"
  if (rnk(r14) /= 14) error stop "rank 14"
  if (rnk(r15) /= 15) error stop "rank 15"
end program
