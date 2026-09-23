! TEST-RULE: 15.6.2.2 15.6.2.4 15.6.2.5
! TEST-PASS: call_other_specific
! One specific may call a different specific of the same generic name.
! The integer block is not part of the real specific, so this is not recursive.
module call_other_specific_m
  implicit none
contains
  generic function widen(x) result(y)
    type(integer, real), intent(in) :: x
    real :: y
    select generic type (x)
    declared type is (integer)
      y = widen(real(x))
    declared type is (real)
      y = x
    end select
  end function

  ! Recursion is permitted without the advisory RECURSIVE prefix. These
  ! calls alternate between the rank-zero and rank-one specifics.
  generic function rank_bounce(x) result(n)
    integer, intent(in), rank(0:1) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      if (x <= 0) then
        n = 0
      else
        n = 1 + rank_bounce([x - 1])
      end if
    rank (1)
      if (x(1) <= 0) then
        n = 0
      else
        n = 1 + rank_bounce(x(1) - 1)
      end if
    end select
  end function

  ! The integer and real specifics mutually invoke one another.
  generic function kind_bounce(x, depth) result(n)
    type(integer, real), intent(in) :: x
    integer, intent(in) :: depth
    integer :: n
    if (depth == 0) then
      n = int(x)
    else
      select generic type (x)
      declared type is (integer)
        n = 1 + kind_bounce(real(x), depth - 1)
      declared type is (real)
        n = 1 + kind_bounce(int(x), depth - 1)
      end select
    end if
  end function
end module

program call_other_specific_p
  use call_other_specific_m
  implicit none
  if (widen(3) /= 3.0) error stop "integer calls real specific"
  if (widen(1.5) /= 1.5) error stop "real specific"
  if (rank_bounce(4) /= 4) error stop "scalar to vector recursion"
  if (rank_bounce([5]) /= 5) error stop "vector to scalar recursion"
  if (kind_bounce(7, 4) /= 11) error stop "cross-kind recursion"
  if (kind_bounce(2.0, 3) /= 5) error stop "cross-kind reverse recursion"
  print '(a)', 'TEST-PASS: call_other_specific'
end program
