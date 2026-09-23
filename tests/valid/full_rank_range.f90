! TEST-RULE: C826 C875 C877 8.5.17 15.6.2.4
! TEST-PASS: full_rank_range
! C826 limits the portable default set to rank 15. Every rank from zero
! through fifteen executes with descriptor, element-order, and value checks.
module full_rank_range_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
contains
  generic function verify_rank(x, expected_rank, first, last) result(code)
    integer, intent(in), rank(0:min(15, max_rank())) :: x
    integer, intent(in) :: expected_rank, first, last
    integer :: code
    integer, allocatable :: flat(:)
    if (rank(x) /= expected_rank) error stop "rank metadata"
    select generic rank (x)
    rank (0)
      if (x /= first .or. first /= last) error stop "scalar value"
      code = x
    rank default
      if (any(lbound(x) /= 1)) error stop "assumed-shape lower bounds"
      if (any(ubound(x) /= shape(x))) error stop "upper bounds"
      if (product(shape(x)) /= 2) error stop "total extent"
      if (count(shape(x) == 2) /= 1) error stop "dimensional extents"
      flat = pack(x, .true.)
      if (any(flat /= [first, last])) error stop "element order and values"
      code = 1000*rank(x) + 10*flat(1) + flat(2)
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

  if (max_rank() < 15) error stop "processor rank below required minimum"
  r1 = reshape([11, 12], shape(r1))
  r2 = reshape([21, 22], shape(r2))
  r3 = reshape([31, 32], shape(r3))
  r4 = reshape([41, 42], shape(r4))
  r5 = reshape([51, 52], shape(r5))
  r6 = reshape([61, 62], shape(r6))
  r7 = reshape([71, 72], shape(r7))
  r8 = reshape([81, 82], shape(r8))
  r9 = reshape([91, 92], shape(r9))
  r10 = reshape([101, 102], shape(r10))
  r11 = reshape([111, 112], shape(r11))
  r12 = reshape([121, 122], shape(r12))
  r13 = reshape([131, 132], shape(r13))
  r14 = reshape([141, 142], shape(r14))
  r15 = reshape([151, 152], shape(r15))

  if (verify_rank(7, 0, 7, 7) /= 7) error stop "rank 0"
  if (verify_rank(r1, 1, 11, 12) /= 1122) error stop "rank 1"
  if (verify_rank(r2, 2, 21, 22) /= 2232) error stop "rank 2"
  if (verify_rank(r3, 3, 31, 32) /= 3342) error stop "rank 3"
  if (verify_rank(r4, 4, 41, 42) /= 4452) error stop "rank 4"
  if (verify_rank(r5, 5, 51, 52) /= 5562) error stop "rank 5"
  if (verify_rank(r6, 6, 61, 62) /= 6672) error stop "rank 6"
  if (verify_rank(r7, 7, 71, 72) /= 7782) error stop "rank 7"
  if (verify_rank(r8, 8, 81, 82) /= 8892) error stop "rank 8"
  if (verify_rank(r9, 9, 91, 92) /= 10002) error stop "rank 9"
  if (verify_rank(r10, 10, 101, 102) /= 11112) error stop "rank 10"
  if (verify_rank(r11, 11, 111, 112) /= 12222) error stop "rank 11"
  if (verify_rank(r12, 12, 121, 122) /= 13332) error stop "rank 12"
  if (verify_rank(r13, 13, 131, 132) /= 14442) error stop "rank 13"
  if (verify_rank(r14, 14, 141, 142) /= 15552) error stop "rank 14"
  if (verify_rank(r15, 15, 151, 152) /= 16662) error stop "rank 15"
  print '(a)', 'TEST-PASS: full_rank_range'
end program
