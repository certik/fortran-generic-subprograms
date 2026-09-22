! TEST-RULE: R831 R832 R833 C875 C876 C877 R1152 8.5.17 11.1.10
! Distinct rank lists, ranges, mixed scalar/range lists, overlapping ranges,
! duplicate collapse, constant-expression bounds, and an empty descending
! range embedded in a nonempty list.
module language_rank_sets_m
  implicit none
  integer, parameter :: one = 1
  integer, parameter :: lo = 1, hi = 3
  integer, parameter, rank(one) :: implied = [2, 3, 5]
contains
  generic function distinct(x) result(n)
    integer, rank(0, 2, 4), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      n = x
    rank (2)
      n = 20 + sum(x)
    rank (4)
      n = 40 + sum(x)
    end select
  end function

  generic function range_only(x) result(n)
    integer, rank(1:3), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (1:3)
      n = 100*rank(x) + sum(x)
    end select
  end function

  generic function mixed_overlap(x) result(n)
    integer, rank(hi:lo, 0, lo:hi, 2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (hi:lo, 0:1, 1:2, 2:hi)
      n = rank(x)
    end select
  end function

  generic function duplicate_rank(x) result(n)
    integer, rank(one, one), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (one, one)
      n = sum(x)
    end select
  end function

  generic function singleton_range(x) result(n)
    integer, rank(2:2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (2:2)
      n = sum(x)
    end select
  end function

  generic function ordinary_named_rank(x, y) result(n)
    type(integer, real), intent(in) :: x
    integer, rank(one), intent(in) :: y
    integer :: n
    select generic type (x)
    declared type is (integer)
      n = x + sum(y)
    declared type is (real)
      n = nint(x) + sum(y)
    end select
  end function
end module

program language_rank_sets_p
  use language_rank_sets_m
  implicit none
  integer :: r1(2), r2(1, 2), r3(1, 1, 2), r4(1, 1, 1, 2)

  r1 = [1, 2]
  r2 = reshape([3, 4], [1, 2])
  r3 = reshape([5, 6], [1, 1, 2])
  r4 = reshape([7, 8], [1, 1, 1, 2])
  if (distinct(9) /= 9) error stop "distinct scalar"
  if (distinct(r2) /= 27) error stop "distinct rank2"
  if (distinct(r4) /= 55) error stop "distinct rank4"
  if (range_only(r1) /= 103) error stop "range rank1"
  if (range_only(r2) /= 207) error stop "range rank2"
  if (range_only(r3) /= 311) error stop "range rank3"
  if (mixed_overlap(1) /= 0) error stop "mixed scalar"
  if (mixed_overlap(r1) /= 1) error stop "mixed rank1"
  if (mixed_overlap(r2) /= 2) error stop "mixed rank2"
  if (mixed_overlap(r3) /= 3) error stop "mixed rank3"
  if (duplicate_rank(r1) /= 3) error stop "duplicate rank remains generic"
  if (singleton_range(r2) /= 7) error stop "singleton range remains generic"
  if (ordinary_named_rank(4, r1) /= 7) error stop "named ordinary rank integer"
  if (ordinary_named_rank(4.0, r1) /= 7) error stop "named ordinary rank real"
  if (rank(implied) /= 1 .or. lbound(implied, 1) /= 1) error stop "implied rank"
  if (any(implied /= [2, 3, 5])) error stop "implied shape value"
end program
