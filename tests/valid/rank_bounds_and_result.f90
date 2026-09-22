! TEST-RULE: C877 8.5.17 11.1.10 15.6.2.4
! Generic rank: assumed-shape lower bounds are 1, the result is allocatable
! deferred-shape, and each SELECT GENERIC RANK block is type-checked only
! for its own rank.
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

  generic subroutine dummy_descriptor(x, lb, ub, ext)
    integer, intent(in), rank(1:2) :: x
    integer, intent(out) :: lb(2), ub(2), ext(2)
    integer :: n
    n = rank(x)
    lb = -99
    ub = -99
    ext = -99
    lb(1:n) = lbound(x)
    ub(1:n) = ubound(x)
    ext(1:n) = shape(x)
  end subroutine
end module

program rank_bounds_p
  use rank_bounds_m
  implicit none
  integer :: v(0:2), m(0:1, 3:4)
  integer :: lb(2), ub(2), ext(2)
  integer, allocatable :: cv(:), cm(:, :), section(:, :)
  integer, allocatable :: empty_first(:, :), empty_second(:, :)
  v = [10, 20, 30]
  m = reshape([1, 2, 3, 4], [2, 2])
  if (rank(copy(5)) /= 0) error stop "copy rank 0"
  if (copy(5) /= 5) error stop "copy scalar"

  cv = copy(v)
  if (rank(cv) /= 1) error stop "copy rank 1"
  if (any(cv /= [10, 20, 30])) error stop "copy vector values"
  if (any(lbound(cv) /= [1]) .or. any(ubound(cv) /= [3])) then
    error stop "copy vector bounds"
  end if
  if (any(shape(cv) /= [3])) error stop "copy vector shape"

  cm = copy(m)
  if (rank(cm) /= 2) error stop "copy rank 2"
  if (any(cm /= reshape([1, 2, 3, 4], [2, 2]))) then
    error stop "copy matrix values"
  end if
  if (any(lbound(cm) /= [1, 1]) .or. any(ubound(cm) /= [2, 2])) then
    error stop "copy matrix bounds"
  end if
  if (any(shape(cm) /= [2, 2])) error stop "copy matrix shape"

  section = copy(m(0:1, 4:3:-1))
  if (any(shape(section) /= [2, 2])) error stop "section shape"
  if (any(section /= reshape([3, 4, 1, 2], [2, 2]))) then
    error stop "section order and values"
  end if
  cv = copy(v(2:0:-1))
  if (any(cv /= [30, 20, 10])) error stop "strided section values"

  if (pick(5) /= 5) error stop "pick scalar"
  if (pick(v) /= 10) error stop "pick vector"
  if (pick(m) /= 1) error stop "pick matrix"

  call dummy_descriptor(v, lb, ub, ext)
  if (any(lb /= [1, -99]) .or. any(ub /= [3, -99])) then
    error stop "rank1 dummy bounds"
  end if
  if (any(ext /= [3, -99])) error stop "rank1 dummy shape"
  call dummy_descriptor(m, lb, ub, ext)
  if (any(lb /= [1, 1]) .or. any(ub /= [2, 2])) then
    error stop "rank2 dummy bounds"
  end if
  if (any(ext /= [2, 2])) error stop "rank2 dummy shape"

  empty_first = copy(m(1:0, 3:4))
  if (any(shape(empty_first) /= [0, 2])) error stop "empty first extent"
  if (any(lbound(empty_first) /= [1, 1])) error stop "empty first lbound"
  if (any(ubound(empty_first) /= [0, 2])) error stop "empty first ubound"
  empty_second = copy(m(0:1, 4:3))
  if (any(shape(empty_second) /= [2, 0])) error stop "empty second extent"
  if (any(lbound(empty_second) /= [1, 1])) error stop "empty second lbound"
  if (any(ubound(empty_second) /= [2, 0])) error stop "empty second ubound"
end program
