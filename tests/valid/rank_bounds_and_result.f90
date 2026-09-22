! Generic rank: assumed-shape lower bounds are 1, the result is allocatable
! deferred-shape, and each SELECT GENERIC RANK block is type-checked only
! for its own rank (8.5.17 p3, 11.1.10).
module rank_bounds_m
  implicit none
contains
  generic function copy(x) result(y)
    integer, intent(in), rank(0:2) :: x
    integer, allocatable, rank(rank(x)) :: y
    y = x
  end function

  generic function pick(x) result(y)
    integer, intent(in), rank(0:2) :: x
    integer :: y
    select generic rank (x)
    rank (0)
      y = x
    rank (1)
      y = x(1)
    rank (2)
      y = x(1, 1)
    end select
  end function

  generic function dummy_lbound(x) result(n)
    integer, intent(in), rank(1:2) :: x
    integer :: n
    n = lbound(x, 1)
  end function
end module

program rank_bounds_p
  use rank_bounds_m
  implicit none
  integer :: v(0:2), m(0:1, 3:4)
  v = [10, 20, 30]
  m = reshape([1, 2, 3, 4], [2, 2])
  if (rank(copy(5)) /= 0) error stop "copy rank 0"
  if (copy(5) /= 5) error stop "copy scalar"
  if (rank(copy(v)) /= 1) error stop "copy rank 1"
  if (any(copy(v) /= [10, 20, 30])) error stop "copy vector values"
  if (lbound(copy(v), 1) /= 1) error stop "copy vector lbound"
  if (rank(copy(m)) /= 2) error stop "copy rank 2"
  if (any(shape(copy(m)) /= [2, 2])) error stop "copy matrix shape"
  if (pick(5) /= 5) error stop "pick scalar"
  if (pick(v) /= 10) error stop "pick vector"
  if (pick(m) /= 1) error stop "pick matrix"
  if (dummy_lbound(v) /= 1) error stop "assumed-shape lbound"
  if (size(copy(v(2:1))) /= 0) error stop "empty copy"
end program
