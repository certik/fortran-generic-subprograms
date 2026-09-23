! TEST-RULE: R1510 C1512 15.4.3.3 15.4.3.4.2 15.4.3.4.3 15.6.2.4
! TEST-PASS: operator_and_assignment
! GENERIC statements route every generated specific to unary and binary
! operators and assignment. Traditional and multiple generated sets merge.
module operator_and_assignment_m
  implicit none
  private
  public :: box, bag, myplus

  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type

  generic, public :: operator(.myplus.) => myplus, logical_myplus
  generic, public :: operator(.twice.) => dbl
  generic, public :: operator(+) => add_wrapped
  generic, public :: assignment(=) => set_from_int
contains
  pure generic function myplus(a, b) result(c)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a + b
  end function

  pure generic function myplus(a, b) result(c)
    type(box, bag), intent(in) :: a
    typeof(a), intent(in) :: b
    integer :: c
    c = a%n + b%n
  end function

  pure logical function logical_myplus(a, b) result(c)
    logical, intent(in) :: a, b
    c = a .or. b
  end function

  pure generic function dbl(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function

  pure generic function dbl(x) result(y)
    type(box, bag), intent(in) :: x
    typeof(x) :: y
    y%n = 2*x%n
  end function

  pure generic function add_wrapped(a, b) result(c)
    type(box, bag), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c%n = a%n + b%n
  end function

  pure generic subroutine set_from_int(a, b)
    type(box, bag), intent(inout) :: a
    integer, intent(in) :: b
    a%n = b
  end subroutine
end module

program operator_and_assignment_p
  use operator_and_assignment_m
  implicit none
  type(box) :: bx, bx2, bx_sum, bx_twice
  type(bag) :: bg, bg2, bg_sum, bg_twice

  if ((2 .myplus. 3) /= 5) error stop "integer binary operator"
  if ((1.5 .myplus. 2.5) /= 4.0) error stop "real binary operator"
  if (.not. (.false. .myplus. .true.)) error stop "traditional merged operator"
  if (myplus(2, 3) /= 5) error stop "generic function form"
  if ((.twice. 4) /= 8) error stop "unary integer"
  if ((.twice. 1.25) /= 2.5) error stop "unary real"

  bx = 9
  bx2 = 4
  bg = 7
  bg2 = 5
  if (bx%n /= 9 .or. bx2%n /= 4) error stop "box assignment"
  if (bg%n /= 7 .or. bg2%n /= 5) error stop "bag assignment"
  if ((bx .myplus. bx2) /= 13) error stop "second generated binary set"
  if ((bg .myplus. bg2) /= 12) error stop "bag generated binary set"

  bx_sum = bx + bx2
  bg_sum = bg + bg2
  if (bx_sum%n /= 13 .or. bg_sum%n /= 12) then
    error stop "intrinsic operator extension"
  end if
  bx_twice = .twice. bx
  bg_twice = .twice. bg
  if (bx_twice%n /= 18 .or. bg_twice%n /= 14) then
    error stop "unary derived types"
  end if
  print '(a)', 'TEST-PASS: operator_and_assignment'
end program
