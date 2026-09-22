! A dummy that is both type-generic and rank-generic: 2 types x 3 ranks.
! Nested SELECT GENERIC constructs, each resolved at compile time.
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
end module

program nested_select_p
  use nested_select_m
  implicit none
  integer :: i1(1), i2(1, 1)
  real :: r1(1), r2(1, 1)
  if (tag(0) /= 11) error stop "integer scalar"
  if (tag(i1) /= 21) error stop "integer rank1"
  if (tag(i2) /= 31) error stop "integer rank2"
  if (tag(0.0) /= 12) error stop "real scalar"
  if (tag(r1) /= 22) error stop "real rank1"
  if (tag(r2) /= 32) error stop "real rank2"
end program
