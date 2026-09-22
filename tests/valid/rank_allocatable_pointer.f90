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
end program
