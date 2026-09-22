! TEST-RULE: R705 R831 11.1.10 11.1.11 15.6.2.4
! Two independent generic dummies: 2 types x 2 ranks x 2 types x 2 ranks
! = 16 specifics. All sixteen are referenced for both specialization tags and
! transported scalar/array values (15.6.2.4 p1).
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

  generic function transported(x, y) result(v)
    type(integer, real), rank(0:1), intent(in) :: x
    type(integer, real), rank(0:1), intent(in) :: y
    real :: v, xv, yv
    select generic type (x)
    declared type is (integer)
      select generic rank (x)
      rank (0)
        xv = real(x)
      rank (1)
        xv = real(sum(x))
      end select
    declared type is (real)
      select generic rank (x)
      rank (0)
        xv = x
      rank (1)
        xv = sum(x)
      end select
    end select
    select generic type (y)
    declared type is (integer)
      select generic rank (y)
      rank (0)
        yv = real(y)
      rank (1)
        yv = real(sum(y))
      end select
    declared type is (real)
      select generic rank (y)
      rank (0)
        yv = y
      rank (1)
        yv = sum(y)
      end select
    end select
    v = 10.0*xv + yv
  end function
end module

program cross_product_p
  use cross_product_m
  implicit none
  integer :: i0, i1(2)
  real :: r0, r1(2)
  i0 = 3
  i1 = [4, 5]
  r0 = 1.5
  r1 = [2.5, 3.5]
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
  if (transported(i0, i0) /= 33.0) error stop "value i0 i0"
  if (transported(i1, i0) /= 93.0) error stop "value i1 i0"
  if (transported(r0, i0) /= 18.0) error stop "value r0 i0"
  if (transported(r1, i0) /= 63.0) error stop "value r1 i0"
  if (transported(i0, i1) /= 39.0) error stop "value i0 i1"
  if (transported(i1, i1) /= 99.0) error stop "value i1 i1"
  if (transported(r0, i1) /= 24.0) error stop "value r0 i1"
  if (transported(r1, i1) /= 69.0) error stop "value r1 i1"
  if (transported(i0, r0) /= 31.5) error stop "value i0 r0"
  if (transported(i1, r0) /= 91.5) error stop "value i1 r0"
  if (transported(r0, r0) /= 16.5) error stop "value r0 r0"
  if (transported(r1, r0) /= 61.5) error stop "value r1 r0"
  if (transported(i0, r1) /= 36.0) error stop "value i0 r1"
  if (transported(i1, r1) /= 96.0) error stop "value i1 r1"
  if (transported(r0, r1) /= 21.0) error stop "value r0 r1"
  if (transported(r1, r1) /= 66.0) error stop "value r1 r1"
end program
