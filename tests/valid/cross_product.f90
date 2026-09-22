! Two independent generic dummies: 2 types x 2 ranks x 2 types x 2 ranks
! = 16 specifics. All sixteen are referenced (15.6.2.4 p1).
module cross_product_m
  implicit none
contains
  generic function tag(x, y) result(n)
    type(integer, real), rank(0:1), intent(in) :: x
    type(integer, real), rank(0:1), intent(in) :: y
    integer :: n
    n = 0
    if (rank(x) < 0 .or. rank(y) < 0) n = -999
    select generic type (x)
    declared type is (integer)
      n = n + 1
    declared type is (real)
      n = n + 2
    end select
    select generic rank (x)
    rank (0)
      n = n + 10
    rank (1)
      n = n + 20
    end select
    select generic type (y)
    declared type is (integer)
      n = n + 100
    declared type is (real)
      n = n + 200
    end select
    select generic rank (y)
    rank (0)
      n = n + 1000
    rank (1)
      n = n + 2000
    end select
  end function
end module

program cross_product_p
  use cross_product_m
  implicit none
  integer :: i0, i1(1)
  real :: r0, r1(1)
  i0 = 0
  i1 = 0
  r0 = 0.0
  r1 = 0.0
  if (tag(i0, i0) /= 1111) error stop "i0 i0"
  if (tag(i1, i0) /= 1121) error stop "i1 i0"
  if (tag(r0, i0) /= 1112) error stop "r0 i0"
  if (tag(r1, i0) /= 1122) error stop "r1 i0"
  if (tag(i0, i1) /= 2111) error stop "i0 i1"
  if (tag(i1, i1) /= 2121) error stop "i1 i1"
  if (tag(r0, i1) /= 2112) error stop "r0 i1"
  if (tag(r1, i1) /= 2122) error stop "r1 i1"
  if (tag(i0, r0) /= 1211) error stop "i0 r0"
  if (tag(i1, r0) /= 1221) error stop "i1 r0"
  if (tag(r0, r0) /= 1212) error stop "r0 r0"
  if (tag(r1, r0) /= 1222) error stop "r1 r0"
  if (tag(i0, r1) /= 2211) error stop "i0 r1"
  if (tag(i1, r1) /= 2221) error stop "i1 r1"
  if (tag(r0, r1) /= 2212) error stop "r0 r1"
  if (tag(r1, r1) /= 2222) error stop "r1 r1"
end program
