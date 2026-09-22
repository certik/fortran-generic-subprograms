! TEST-RULE: R1150 R1155 11.1.10 11.1.11 15.6.2.4
! A dummy that is both type-generic and rank-generic: 2 types x 3 ranks.
! The original sequential checks are retained, followed by genuine nesting in
! both orders and nesting whose selectors are independent dummies.
module nested_select_m
  implicit none
contains
  generic function tag(x) result(n)
    type(integer, real), rank(0:2), intent(in) :: x
    integer :: n
    n = 0
    select generic type (x)
    declared type is (integer)
      n = 1
    declared type is (real)
      n = 2
    end select
    select generic rank (x)
    rank (0)
      n = n + 10
    rank (1)
      n = n + 20
    rank (2)
      n = n + 30
    end select
  end function

  generic function type_outer(x) result(n)
    type(integer, real), rank(0:2), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer)
      select generic rank (x)
      rank (0)
        n = 11
      rank (1)
        n = 21
      rank (2)
        n = 31
      end select
    declared type is (real)
      select generic rank (x)
      rank (0)
        n = 12
      rank (1)
        n = 22
      rank (2)
        n = 32
      end select
    end select
  end function

  generic function rank_outer(x) result(n)
    type(integer, real), rank(0:2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      select generic type (x)
      declared type is (integer)
        n = 11
      declared type is (real)
        n = 12
      end select
    rank (1)
      select generic type (x)
      declared type is (integer)
        n = 21
      declared type is (real)
        n = 22
      end select
    rank (2)
      select generic type (x)
      declared type is (integer)
        n = 31
      declared type is (real)
        n = 32
      end select
    end select
  end function

  generic function independent(x, y) result(n)
    type(integer, real), intent(in) :: x
    integer, rank(0:1), intent(in) :: y
    integer :: n
    select generic rank (y)
    rank (0)
      select generic type (x)
      declared type is (integer)
        n = 101
      declared type is (real)
        n = 102
      end select
    rank (1)
      select generic type (x)
      declared type is (integer)
        n = 201
      declared type is (real)
        n = 202
      end select
    end select
  end function
end module

program nested_select_p
  use nested_select_m
  implicit none
  integer :: i1(1), i2(1, 1), selector(2)
  real :: r1(1), r2(1, 1)
  i1 = 1
  i2 = 2
  r1 = 1.0
  r2 = 2.0
  selector = [3, 4]
  if (tag(0) /= 11) error stop "integer scalar"
  if (tag(i1) /= 21) error stop "integer rank1"
  if (tag(i2) /= 31) error stop "integer rank2"
  if (tag(0.0) /= 12) error stop "real scalar"
  if (tag(r1) /= 22) error stop "real rank1"
  if (tag(r2) /= 32) error stop "real rank2"
  if (type_outer(0) /= 11 .or. rank_outer(0) /= 11) error stop "nested integer scalar"
  if (type_outer(i1) /= 21 .or. rank_outer(i1) /= 21) error stop "nested integer rank1"
  if (type_outer(i2) /= 31 .or. rank_outer(i2) /= 31) error stop "nested integer rank2"
  if (type_outer(0.0) /= 12 .or. rank_outer(0.0) /= 12) error stop "nested real scalar"
  if (type_outer(r1) /= 22 .or. rank_outer(r1) /= 22) error stop "nested real rank1"
  if (type_outer(r2) /= 32 .or. rank_outer(r2) /= 32) error stop "nested real rank2"
  if (independent(1, 2) /= 101) error stop "independent integer scalar"
  if (independent(1.0, 2) /= 102) error stop "independent real scalar"
  if (independent(1, selector) /= 201) error stop "independent integer rank1"
  if (independent(1.0, selector) /= 202) error stop "independent real rank1"
end program
