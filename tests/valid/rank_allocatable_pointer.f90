! TEST-RULE: 8.5.3 8.5.8.4 C877 15.5.2.7 15.6.2.4
! Allocatable and pointer generic ranks retain every bound of their actual.
module rank_alloc_ptr_m
  implicit none
contains
  generic subroutine fill(x)
    integer, allocatable, rank(0:2), intent(out) :: x
    select generic rank (x)
    rank (0)
      allocate(x)
      x = 99
    rank (1)
      allocate(x(0:2))
      x = [10, 20, 30]
    rank (2)
      allocate(x(-1:0, 5:6))
      x = reshape([1, 2, 3, 4], [2, 2])
    end select
  end subroutine

  generic subroutine alloc_descriptor(x, bounds)
    integer, allocatable, rank(0:2), intent(in) :: x
    integer, intent(out) :: bounds(4)
    bounds = 0
    select generic rank (x)
    rank (0)
      bounds = [0, 0, 0, 0]
    rank (1)
      bounds = [lbound(x, 1), ubound(x, 1), 0, 0]
    rank (2)
      bounds = [lbound(x, 1), ubound(x, 1), &
                lbound(x, 2), ubound(x, 2)]
    end select
  end subroutine

  generic function alloc_present(x) result(answer)
    integer, allocatable, rank(0:2), intent(in) :: x
    logical :: answer
    answer = allocated(x)
  end function

  generic subroutine point_at(p, t)
    integer, pointer, rank(0:2) :: p
    integer, target, rank(rank(p)) :: t
    p => t
  end subroutine

  generic subroutine pointer_descriptor(p, bounds, checksum)
    integer, pointer, intent(in), rank(0:2) :: p
    integer, intent(out) :: bounds(4), checksum
    bounds = 0
    checksum = 0
    if (.not. associated(p)) return
    select generic rank (p)
    rank (0)
      checksum = p
    rank (1)
      bounds = [lbound(p, 1), ubound(p, 1), 0, 0]
      checksum = sum(p)
    rank (2)
      bounds = [lbound(p, 1), ubound(p, 1), &
                lbound(p, 2), ubound(p, 2)]
      checksum = sum(p)
    end select
  end subroutine

  generic function pointer_present(p) result(answer)
    integer, pointer, intent(in), rank(0:2) :: p
    logical :: answer
    answer = associated(p)
  end function

  generic subroutine add_hundred(x)
    integer, intent(inout), rank(1:2) :: x
    x = x + 100
  end subroutine

  generic subroutine add_thousand(p)
    integer, pointer, intent(inout), rank(0:2) :: p
    p = p + 1000
  end subroutine
end module

program rank_alloc_ptr_p
  use rank_alloc_ptr_m
  implicit none
  integer, allocatable :: scalar, row(:), grid(:, :)
  integer, allocatable :: unallocated_scalar, unallocated_grid(:, :)
  integer, target :: scalar_target, vec(4), mat(2, 3)
  integer, pointer :: ps => null(), pv(:) => null(), pm(:, :) => null()
  integer, pointer :: null_scalar => null()
  integer, pointer :: null_vector(:) => null()
  integer :: bounds(4), checksum, i
  integer :: line(10), plane(4, 4)
  call fill(scalar)
  call fill(row)
  call fill(grid)
  if (.not. allocated(scalar) .or. scalar /= 99) then
    error stop "fill scalar allocatable"
  end if
  if (any(lbound(row) /= [0])) error stop "fill rank1 lbound"
  if (any(row /= [10, 20, 30])) error stop "fill rank1"
  if (any(lbound(grid) /= [-1, 5]) .or. &
      any(ubound(grid) /= [0, 6])) error stop "fill rank2 bounds"
  if (any(grid /= reshape([1, 2, 3, 4], [2, 2]))) then
    error stop "fill rank2 values"
  end if
  call alloc_descriptor(scalar, bounds)
  if (any(bounds /= 0)) error stop "scalar allocatable descriptor"
  call alloc_descriptor(row, bounds)
  if (any(bounds /= [0, 2, 0, 0])) error stop "rank1 alloc bounds"
  call alloc_descriptor(grid, bounds)
  if (any(bounds /= [-1, 0, 5, 6])) error stop "rank2 alloc bounds"
  if (alloc_present(unallocated_scalar)) error stop "unallocated scalar"
  if (alloc_present(unallocated_grid)) error stop "unallocated rank2"

  scalar_target = 8
  vec = [1, 2, 3, 4]
  mat = reshape([1, 2, 3, 4, 5, 6], [2, 3])
  call point_at(ps, scalar_target)
  call point_at(pv, vec)
  call point_at(pm, mat)
  if (.not. associated(ps, scalar_target)) error stop "pointer scalar"
  if (.not. associated(pv, vec)) error stop "pointer rank1"
  if (.not. associated(pm, mat)) error stop "pointer rank2"
  if (ps /= 8 .or. pv(2) /= 2 .or. pm(1, 2) /= 3) then
    error stop "pointer values"
  end if
  call pointer_descriptor(ps, bounds, checksum)
  if (any(bounds /= 0) .or. checksum /= 8) error stop "scalar pointer descriptor"
  call pointer_descriptor(pm, bounds, checksum)
  if (any(bounds /= [1, 2, 1, 3]) .or. checksum /= 21) then
    error stop "rank2 pointer descriptor"
  end if
  call add_thousand(ps)
  if (scalar_target /= 1008) error stop "scalar pointer update"
  call add_thousand(pm)
  if (any(mat /= reshape([1001, 1002, 1003, 1004, 1005, 1006], [2, 3]))) then
    error stop "rank2 pointer update"
  end if
  if (pointer_present(null_scalar)) error stop "disassociated scalar"
  if (pointer_present(null_vector)) error stop "disassociated rank1"

  block
    integer, target :: storage(0:8)
    integer, target :: grid(-2:0, 4:5)
    integer, pointer :: incoming(:)
    integer, pointer :: incoming2(:, :)
    storage = [(i, i=0, 8)]
    incoming => storage(0:8:2)
    call pointer_descriptor(incoming, bounds, checksum)
    if (any(bounds /= [1, 5, 0, 0])) error stop "strided pointer bounds"
    if (checksum /= 20) error stop "strided pointer values"
    call add_thousand(incoming)
    if (any(storage(0:8:2) /= [1000, 1002, 1004, 1006, 1008])) then
      error stop "strided pointer update"
    end if
    if (any(storage(1:7:2) /= [1, 3, 5, 7])) then
      error stop "strided pointer isolation"
    end if
    grid = reshape([1, 2, 3, 4, 5, 6], [3, 2])
    incoming2 => grid
    call pointer_descriptor(incoming2, bounds, checksum)
    if (any(bounds /= [-2, 0, 4, 5])) error stop "pointer rank2 bounds"
    if (checksum /= 21) error stop "pointer rank2 values"
  end block

  line = [(i, i=1, 10)]
  call add_hundred(line(1:10:2))
  if (any(line(1:10:2) /= [101, 103, 105, 107, 109])) then
    error stop "rank1 noncontiguous copy-back"
  end if
  if (any(line(2:10:2) /= [2, 4, 6, 8, 10])) then
    error stop "rank1 noncontiguous isolation"
  end if
  plane = reshape([(i, i=1, 16)], [4, 4])
  call add_hundred(plane(1:4:2, 2:4:2))
  if (any(plane(1:4:2, 2:4:2) /= &
      reshape([105, 107, 113, 115], [2, 2]))) then
    error stop "rank2 noncontiguous copy-back"
  end if
  if (any(plane(2:4:2, 2:4:2) /= &
      reshape([6, 8, 14, 16], [2, 2]))) then
    error stop "rank2 row isolation"
  end if
  if (any(plane(:, 1:3:2) /= &
      reshape([1, 2, 3, 4, 9, 10, 11, 12], [4, 2]))) then
    error stop "rank2 column isolation"
  end if
end program
