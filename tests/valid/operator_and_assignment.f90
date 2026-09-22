! PROCEDURE of a generic name adds every specific to an operator or to
! defined assignment (15.4.3.3 p3). The specific name may be private.
module operator_and_assignment_m
  implicit none
  private
  public operator(.myplus.), operator(.twice.), assignment(=), myplus
  interface operator(.myplus.)
    procedure myplus
  end interface
  interface operator(.twice.)
    procedure dbl
  end interface
  interface assignment(=)
    procedure set_from_int
  end interface
  type, public :: box
    integer :: n = 0
  end type
  type, public :: bag
    integer :: n = 0
  end type
contains
  pure generic function myplus(a, b) result(c)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a + b
  end function

  pure generic function dbl(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + x
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
  type(box) :: bx
  type(bag) :: bg
  if ((2 .myplus. 3) /= 5) error stop "integer operator"
  if ((1.5 .myplus. 2.5) /= 4.0) error stop "real operator"
  if (myplus(2, 3) /= 5) error stop "function form"
  if ((.twice. 4) /= 8) error stop "unary integer"
  if ((.twice. 1.25) /= 2.5) error stop "unary real"
  bx = 9
  bg = 4
  if (bx%n /= 9 .or. bg%n /= 4) error stop "defined assignment"
end program
