! Allocatable generic rank keeps the actual's bounds. Pointer generic rank
! is deferred-shape and pointer-assigns to a target whose rank follows it
! (8.5.8.4, 8.5.17 p3).
module rank_alloc_ptr_m
  implicit none
contains
  generic subroutine fill(x)
    integer, allocatable, rank(1:2), intent(out) :: x
    select generic rank (x)
    rank (1)
      allocate(x(0:2))
      x = [10, 20, 30]
    rank (2)
      allocate(x(-1:0, 5:6))
      x = reshape([1, 2, 3, 4], [2, 2])
    end select
  end subroutine

  generic function alloc_lbound(x) result(n)
    integer, allocatable, rank(1:1), intent(in) :: x
    integer :: n
    n = lbound(x, 1)
  end function

  generic subroutine point_at(p, t)
    integer, pointer, rank(1:2) :: p
    integer, target, rank(rank(p)) :: t
    p => t
  end subroutine

  ! A pointer dummy is deferred-shape: it keeps the actual pointer's bounds,
  ! including a lower bound other than 1 (8.5.8.4).
  generic subroutine pointer_bounds(p, lb1, ub1)
    integer, pointer, intent(in), rank(1:2) :: p
    integer, intent(out) :: lb1, ub1
    lb1 = lbound(p, 1)
    ub1 = ubound(p, 1)
  end subroutine
end module

program rank_alloc_ptr_p
  use rank_alloc_ptr_m
  implicit none
  integer, allocatable :: row(:), grid(:, :)
  integer, allocatable :: passed(:)
  integer, target :: vec(4), mat(2, 3)
  integer, pointer :: pv(:) => null(), pm(:, :) => null()
  call fill(row)
  call fill(grid)
  if (any(lbound(row) /= [0])) error stop "fill rank1 lbound"
  if (any(row /= [10, 20, 30])) error stop "fill rank1"
  if (any(lbound(grid) /= [-1, 5])) error stop "fill rank2 lbound"
  if (grid(-1, 5) /= 1) error stop "fill rank2 value"
  allocate(passed(0:2))
  passed = [7, 8, 9]
  if (alloc_lbound(passed) /= 0) error stop "allocatable dummy keeps lbound"
  vec = [1, 2, 3, 4]
  mat = reshape([1, 2, 3, 4, 5, 6], [2, 3])
  call point_at(pv, vec)
  call point_at(pm, mat)
  if (.not. associated(pv, vec)) error stop "pointer rank1"
  if (.not. associated(pm, mat)) error stop "pointer rank2"
  if (pv(2) /= 2 .or. pm(1, 2) /= 3) error stop "pointer values"

  block
    integer, target :: storage(0:4)
    integer, target :: grid(-2:0, 4:5)
    integer, pointer :: incoming(:)
    integer, pointer :: incoming2(:, :)
    integer :: lb, ub
    storage = [1, 2, 3, 4, 5]
    incoming => storage
    call pointer_bounds(incoming, lb, ub)
    if (lb /= 0 .or. ub /= 4) error stop "pointer rank1 bounds"
    if (incoming(0) /= 1) error stop "pointer rank1 value"
    grid = 7
    incoming2 => grid
    call pointer_bounds(incoming2, lb, ub)
    if (lb /= -2 .or. ub /= 0) error stop "pointer rank2 bounds"
    if (lbound(incoming2, 2) /= 4) error stop "pointer rank2 lbound2"
  end block
end program
