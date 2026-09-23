! TEST-RULE: C15135 C15137 8.5.17 15.9.2 15.6.2.4
! TEST-PASS: elemental
! ELEMENTAL applies to each scalar specific. Array actuals are elemental
! references, not generic-rank matches. RANK(0:0) is generic and still scalar.
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

  elemental generic function combine(x, y) result(z)
    integer, rank(0:0), intent(in) :: x
    integer, intent(in) :: y
    integer :: z
    z = 10*x + y
  end function

  elemental generic function value_plus_two(x) result(y)
    integer, rank(0:0), value :: x
    integer :: y
    x = x + 2
    y = x
  end function
end module

program elemental_p
  use elemental_m
  implicit none
  integer :: a(3), a_before(3), left(2, 3), right(2, 3)
  integer :: empty(0, 2)
  real :: b(2, 2)
  a = [1, 2, 3]
  a_before = a
  b = reshape([0.5, 1.5, 2.5, 3.5], [2, 2])
  left = reshape([1, 2, 3, 4, 5, 6], [2, 3])
  right = reshape([6, 5, 4, 3, 2, 1], [2, 3])
  if (add_one(4) /= 5) error stop "scalar integer"
  if (add_one(1.25) /= 2.25) error stop "scalar real"
  if (any(add_one(a) /= [2, 3, 4])) error stop "elemental integer"
  if (any(shape(add_one(b)) /= [2, 2])) error stop "elemental real shape"
  if (any(add_one(b) /= reshape([1.5, 2.5, 3.5, 4.5], [2, 2]))) then
    error stop "elemental real values"
  end if
  if (id(5) /= 5) error stop "rank 0:0 scalar"
  if (any(id(a) /= a)) error stop "rank 0:0 elemental"
  if (any(shape(id(empty)) /= [0, 2])) error stop "empty elemental shape"
  if (any(shape(combine(left, right)) /= [2, 3])) then
    error stop "two-array conformance shape"
  end if
  if (any(combine(left, right) /= 10*left + right)) then
    error stop "two-array elemental values"
  end if
  if (any(combine(a, 7) /= [17, 27, 37])) then
    error stop "scalar expansion"
  end if
  if (any(value_plus_two(a) /= [3, 4, 5])) error stop "elemental value"
  if (any(a /= a_before)) error stop "value changed actual"
  print '(a)', 'TEST-PASS: elemental'
end program
