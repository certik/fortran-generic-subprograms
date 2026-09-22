! ELEMENTAL applies to each scalar specific. Array actuals are elemental
! references, not generic-rank matches. RANK(0:0) is generic and still scalar,
! so it may be elemental (C15135, 8.5.17 p2).
module elemental_m
  implicit none
contains
  elemental generic function add_one(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + 1
  end function

  elemental generic function id(x) result(y)
    integer, rank(0:0), intent(in) :: x
    integer :: y
    select generic rank (x)
    rank (0)
      y = x
    rank default
      y = -1
    end select
  end function
end module

program elemental_p
  use elemental_m
  implicit none
  integer :: a(3)
  real :: b(2, 2)
  a = [1, 2, 3]
  b = 1.5
  if (add_one(4) /= 5) error stop "scalar integer"
  if (add_one(1.25) /= 2.25) error stop "scalar real"
  if (any(add_one(a) /= [2, 3, 4])) error stop "elemental integer"
  if (any(add_one(b) /= 2.5)) error stop "elemental real"
  if (id(5) /= 5) error stop "rank 0:0 scalar"
  if (any(id(a) /= a)) error stop "rank 0:0 elemental"
end program
