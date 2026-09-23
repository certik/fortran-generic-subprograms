! TEST-RULE: R1506 R1507 C1505 C1510 15.4.3.2 15.4.3.4.1 15.4.3.4.2 15.4.3.4.3 15.6.2.4
! TEST-PASS: audit_routes_operator_assignment
! PROCEDURE statements in operator and assignment interface blocks name
! generic subprograms, so each adds every generated specific
! (15.4.3.4.1 p2). valid/operator_and_assignment.f90 covers the GENERIC
! statement route. Operator dummies use INTENT(IN) or VALUE; assignment uses
! INTENT(OUT) or INTENT(INOUT) with an INTENT(IN) or VALUE second dummy. Every
! generated specific is referenced, and each VALUE actual is checked unchanged.
! The families stay private: only the operators and assignment are public.
module audit_routes_operator_assignment_m
  implicit none
  private
  public :: box, bag
  public :: operator(.neg.), operator(.join.), operator(-), operator(*)
  public :: assignment(=)

  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type

  interface operator(.neg.)
    procedure negate
  end interface
  interface operator(.join.)
    procedure join, join_logical
  end interface
  interface operator(-)
    procedure :: flip
  end interface
  interface operator(*)
    procedure scale_item
  end interface
  interface assignment(=)
    procedure assign_count
    procedure :: assign_flags
  end interface
contains
  ! Defined unary operator with a VALUE dummy: INTEGER and REAL specifics.
  generic function negate(x) result(y)
    type(integer, real), value :: x
    typeof(x) :: y
    x = -x
    y = x
  end function

  ! Defined binary operator, VALUE left and INTENT(IN) right: four specifics.
  generic function join(a, b) result(code)
    type(integer, real), value :: a
    type(integer, real), intent(in) :: b
    integer :: code
    a = a + a
    select generic type (a)
    declared type is (integer)
      code = 1000 + 10*a
    declared type is (real)
      code = 2000 + nint(10*a)
    end select
    select generic type (b)
    declared type is (integer)
      code = code + 100 + b
    declared type is (real)
      code = code + 200 + nint(b)
    end select
  end function

  integer function join_logical(a, b)
    logical, intent(in) :: a, b
    join_logical = 5000 + merge(10, 0, a) + merge(1, 0, b)
  end function

  ! Intrinsic unary operator extended for derived types with a VALUE dummy.
  generic function flip(item) result(flipped)
    type(box, bag), value :: item
    typeof(item) :: flipped
    item%n = -item%n
    flipped = item
  end function

  ! Intrinsic binary operator, INTENT(IN) left and VALUE right.
  generic function scale_item(item, factor) result(scaled)
    type(box, bag), intent(in) :: item
    integer, value :: factor
    typeof(item) :: scaled
    factor = factor + 1
    select generic type (item)
    declared type is (box)
      scaled%n = 100*item%n + factor
    declared type is (bag)
      scaled%n = 200*item%n + factor
    end select
  end function

  ! INTENT(OUT) first dummy and VALUE second dummy.
  generic subroutine assign_count(lhs, rhs)
    type(box, bag), intent(out) :: lhs
    integer, value :: rhs
    rhs = rhs + 1
    select generic type (lhs)
    declared type is (box)
      lhs%n = 100 + rhs
    declared type is (bag)
      lhs%n = 200 + rhs
    end select
  end subroutine

  ! INTENT(INOUT) first dummy and a rank-generic INTENT(IN) second dummy.
  generic subroutine assign_flags(lhs, rhs)
    type(box, bag), intent(inout) :: lhs
    logical, intent(in), rank(0:1) :: rhs
    select generic rank (rhs)
    rank (0)
      lhs%n = lhs%n + merge(1, 0, rhs)
    rank (1)
      lhs%n = lhs%n + 10*count(rhs)
    end select
    select generic type (lhs)
    declared type is (box)
      lhs%n = lhs%n + 1000
    declared type is (bag)
      lhs%n = lhs%n + 2000
    end select
  end subroutine
end module

program audit_routes_operator_assignment_p
  use audit_routes_operator_assignment_m
  implicit none
  integer :: i, j, k
  real :: r, s
  type(box) :: bx, bx_result
  type(bag) :: bg, bg_result

  i = 3
  r = 1.5
  if ((.neg. i) /= -3 .or. i /= 3) error stop "unary integer VALUE"
  if (kind(.neg. i) /= kind(i)) error stop "unary integer kind"
  if ((.neg. r) /= -1.5 .or. r /= 1.5) error stop "unary real VALUE"
  if (kind(.neg. r) /= kind(r)) error stop "unary real kind"

  i = 2
  j = 3
  r = 2.0
  s = 3.0
  if ((i .join. j) /= 1143) error stop "binary integer integer"
  if ((i .join. s) /= 1243) error stop "binary integer real"
  if ((r .join. j) /= 2143) error stop "binary real integer"
  if ((r .join. s) /= 2243) error stop "binary real real"
  if (i /= 2 .or. r /= 2.0) error stop "binary VALUE actual changed"
  if ((.true. .join. .false.) /= 5010) error stop "named specific in list"

  bx%n = 4
  bg%n = 6
  bx_result = -bx
  bg_result = -bg
  if (bx_result%n /= -4 .or. bx%n /= 4) error stop "unary box VALUE"
  if (bg_result%n /= -6 .or. bg%n /= 6) error stop "unary bag VALUE"

  k = 2
  bx_result = bx*k
  bg_result = bg*k
  if (bx_result%n /= 403) error stop "intrinsic binary box"
  if (bg_result%n /= 1203) error stop "intrinsic binary bag"
  if (k /= 2) error stop "intrinsic binary VALUE actual changed"

  k = 5
  bx = k
  bg = k
  if (bx%n /= 106) error stop "assignment VALUE box"
  if (bg%n /= 206) error stop "assignment VALUE bag"
  if (k /= 5) error stop "assignment VALUE actual changed"

  bx = .true.
  bg = .false.
  if (bx%n /= 1107) error stop "assignment scalar flags box"
  if (bg%n /= 2206) error stop "assignment scalar flags bag"
  bx = [.true., .false., .true.]
  bg = [.true., .true., .true.]
  if (bx%n /= 2127) error stop "assignment vector flags box"
  if (bg%n /= 4236) error stop "assignment vector flags bag"
  print '(a)', 'TEST-PASS: audit_routes_operator_assignment'
end program
