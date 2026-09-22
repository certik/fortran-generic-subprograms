! TEST-RULE: R705 R707 R708 R831 R832 7.3.2.2 8.5.17 11.1.10 11.1.11
! TEST-REQUIRES: int32
! After duplicate removal a single combination is still generic, because
! genericity is syntactic (7.3.2.2 p3, 8.5.17 p2). SELECT GENERIC is therefore
! legal on TYPE(INTEGER, INTEGER), on a one-element kind array, and on RANK(2, 2).
module duplicates_remain_generic_m
  use, intrinsic :: iso_fortran_env, only: int32
  implicit none
contains
  generic function inc_dup_type(x) result(y)
    type(integer, integer), intent(in) :: x
    typeof(x) :: y
    select generic type (x)
    declared type is (integer)
      y = x + 1
    declared type default
      y = -1
    end select
  end function

  generic function inc_one_kind(x) result(y)
    type(integer([int32])), intent(in) :: x
    typeof(x) :: y
    select generic type (x)
    declared type is (integer(int32))
      y = x + 1
    declared type default
      y = -1
    end select
  end function

  generic function first(x) result(y)
    integer, rank(2, 2), intent(in) :: x
    integer :: y
    select generic rank (x)
    rank (2, 2)
      y = x(1, 1)
    rank default
      y = -1
    end select
  end function
end module

program duplicates_remain_generic_p
  use, intrinsic :: iso_fortran_env, only: int32
  use duplicates_remain_generic_m
  implicit none
  integer :: a(2, 2)
  if (int32 < 0) error stop "need int32"
  if (inc_dup_type(4) /= 5) error stop "duplicate type list"
  if (inc_one_kind(4_int32) /= 5_int32) error stop "one-element kind array"
  a = reshape([7, 8, 9, 10], [2, 2])
  if (first(a) /= 7) error stop "duplicate rank list"
end program
