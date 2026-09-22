! TEST-RULE: 15.5.5.2 15.9.2 C.10.6
! An elemental specific is distinguished as if it were scalar. When an
! array actual matches both that elemental specific and a nonelemental
! specific, the nonelemental one is chosen (15.5.5.2 p1–p2, C.10.6 p5).
module elemental_tie_break_m
  implicit none
contains
  elemental generic function pick(x) result(y)
    integer, intent(in) :: x
    integer :: y
    y = x + 1
  end function

  generic function pick(x) result(y)
    integer, intent(in), rank(1) :: x
    integer :: y
    y = 100 + sum(x)
  end function
end module

program elemental_tie_break_p
  use elemental_tie_break_m
  implicit none
  integer :: row(3), grid(2, 2)
  row = [1, 2, 3]
  grid = reshape([1, 2, 3, 4], [2, 2])
  if (pick(4) /= 5) error stop "scalar is elemental"
  if (pick(row) /= 106) error stop "rank 1 is nonelemental"
  if (any(shape(pick(grid)) /= [2, 2])) error stop "rank 2 shape"
  if (any(pick(grid) /= grid + 1)) error stop "rank 2 is elemental"
end program
