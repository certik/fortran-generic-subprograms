! TEST-RULE: C826 C875 8.5.17 15.6.2.4 17.10.2.24
! Portable coarray rank sets are capped by rank+corank<=15 even if a
! processor reports a larger extension through MAX_RANK.
program coarray_rank_p
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
  integer :: scalar[*]
  integer :: vector(2)[*]
  real :: real_vector(2)[*]
  integer :: r2(1, 2)[*]
  integer :: r3(1, 1, 2)[*]
  integer :: r4(1, 1, 1, 2)[*]
  integer :: r5(1, 1, 1, 1, 2)[*]
  integer :: r6(1, 1, 1, 1, 1, 2)[*]
  integer :: r7(1, 1, 1, 1, 1, 1, 2)[*]
  integer :: r8(1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: r9(1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: r10(1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: r11(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: r12(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: r13(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: high(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[*]
  integer :: two_scalar[1, *]
  integer :: two_vector(2)[1, *]
  integer :: corank_limit[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, *]
  integer :: rank_for_corank16

  if (max_rank(corank=0) /= max_rank()) error stop "corank zero inquiry"
  if (max_rank(corank=1) < 14) error stop "corank-one minimum"
  if (max_rank(corank=2) < 13) error stop "corank-two minimum"
  if (max_rank(corank=15) < 0) error stop "corank-limit scalar"
  rank_for_corank16 = max_rank(corank=16)
  ! An extension may support corank 16. If it does not, 17.10.2.24 requires
  ! exactly -HUGE(0_STANDARD_INTEGER). With no DEFAULT KIND statement here,
  ! the literal zero has that standard-integer kind.
  if (rank_for_corank16 < 0 .and. rank_for_corank16 /= -huge(0)) then
    error stop "unsupported-corank sentinel"
  end if

  scalar = 11
  vector = [12, 13]
  real_vector = [1.25, 2.75]
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
  high = reshape([141, 142], shape(high))
  two_scalar = 21
  two_vector = [22, 23]
  corank_limit = 151

  if (verify_c1(scalar, 11.0, 11.0) /= 11) error stop "scalar coarray"
  if (verify_c1(vector, 12.0, 13.0) /= 1133) error stop "rank-one coarray"
  if (verify_c1(real_vector, 1.25, 2.75) /= 1015) then
    error stop "type-generic real coarray"
  end if
  if (verify_c1(r2, 21.0, 22.0) /= 2232) error stop "rank-two coarray"
  if (verify_c1(r3, 31.0, 32.0) /= 3342) error stop "rank-three coarray"
  if (verify_c1(r4, 41.0, 42.0) /= 4452) error stop "rank-four coarray"
  if (verify_c1(r5, 51.0, 52.0) /= 5562) error stop "rank-five coarray"
  if (verify_c1(r6, 61.0, 62.0) /= 6672) error stop "rank-six coarray"
  if (verify_c1(r7, 71.0, 72.0) /= 7782) error stop "rank-seven coarray"
  if (verify_c1(r8, 81.0, 82.0) /= 8892) error stop "rank-eight coarray"
  if (verify_c1(r9, 91.0, 92.0) /= 10002) error stop "rank-nine coarray"
  if (verify_c1(r10, 101.0, 102.0) /= 11112) error stop "rank-ten coarray"
  if (verify_c1(r11, 111.0, 112.0) /= 12222) error stop "rank-eleven coarray"
  if (verify_c1(r12, 121.0, 122.0) /= 13332) error stop "rank-twelve coarray"
  if (verify_c1(r13, 131.0, 132.0) /= 14442) error stop "rank-thirteen coarray"
  if (verify_c1(high, 141.0, 142.0) /= 15552) then
    error stop "rank-fourteen coarray"
  end if
  if (verify_c2(two_scalar) /= 21) error stop "corank-two scalar"
  if (verify_c2(two_vector) /= 145) error stop "corank-two vector"
  if (verify_c15(corank_limit) /= 151) error stop "corank-fifteen scalar"
contains
  generic function verify_c1(x, first, last) result(code)
    type(integer, real), intent(in), &
      rank(0:min(14, max_rank(corank=1))) :: x[*]
    real, intent(in) :: first, last
    integer :: code
    real, allocatable :: flat(:)
    select generic rank (x)
    rank (0)
      if (real(x) /= first .or. first /= last) error stop "c1 scalar value"
      code = nint(first)
    rank default
      if (any(lbound(x) /= 1)) error stop "c1 lower bounds"
      if (any(ubound(x) /= shape(x))) error stop "c1 upper bounds"
      if (product(shape(x)) /= 2) error stop "c1 shape"
      if (count(shape(x) == 2) /= 1) error stop "c1 dimensional extents"
      flat = pack(real(x), .true.)
      if (any(flat /= [first, last])) error stop "c1 data"
      code = 1000*rank(x) + nint(10*first + last)
    end select
  end function

  generic function verify_c2(x) result(code)
    integer, intent(in), rank(0:min(13, max_rank(corank=2))) :: x[1, *]
    integer :: code
    select generic rank (x)
    rank (0)
      code = x
    rank default
      if (any(lbound(x) /= 1)) error stop "c2 lower bounds"
      code = 100*rank(x) + sum(x)
    end select
  end function

  generic function verify_c15(x) result(code)
    integer, intent(in), rank(0) :: &
      x[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, *]
    integer :: code
    code = x
  end function
end program
