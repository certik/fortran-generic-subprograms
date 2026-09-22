! 15.6.2.4 NOTE 2, made runnable.
! subxy: x and y are independent (3 kinds x 2 ranks each = 36). z follows
! the type of x and the rank of y. Only a sample of the 36 is called; every
! combination must still be a legal procedure.
! lift: y is dependent, so there are 6 specifics and x, y, z agree.
module standard_note_shapes_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
contains
  generic subroutine probe(x, y, zt, zr)
    type(integer([int32, int64]), real), rank(1:2), intent(in) :: x
    type(integer([int32, int64]), real), rank(1:2), intent(in) :: y
    integer, intent(out) :: zt, zr
    typeof(x), allocatable, rank(rank(y)) :: z
    select generic type (x)
    declared type is (integer(int32))
      zt = 32
    declared type is (integer(int64))
      zt = 64
    declared type is (real)
      zt = 1
    end select
    select generic rank (y)
    rank (1)
      allocate(z(1))
    rank (2)
      allocate(z(1, 1))
    end select
    zr = rank(z)
  end subroutine

  generic subroutine lift(x, y)
    type(integer([int32, int64]), real), rank(1:2), allocatable :: x
    typeof(x), rank(rank(x)), allocatable :: y
    y = x
    y = y + 1
  end subroutine
end module

program standard_note_shapes_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use standard_note_shapes_m
  implicit none
  integer(int32) :: i32_1(2), i32_2(2, 2)
  integer(int64) :: i64_1(2)
  real :: r_1(2), r_2(2, 2)
  integer :: zt, zr
  integer(int32), allocatable :: li(:), li_out(:)
  integer(int64), allocatable :: lj(:), lj_out(:)
  real, allocatable :: lr(:, :), lr_out(:, :)
  if (int32 <= 0 .or. int64 <= 0) error stop "need int32 and int64"
  i32_1 = 1
  i32_2 = 1
  i64_1 = 1
  r_1 = 1.0
  r_2 = 1.0
  call probe(i32_1, r_2, zt, zr)
  if (zt /= 32 .or. zr /= 2) error stop "z type from x, rank from y"
  call probe(r_2, i64_1, zt, zr)
  if (zt /= 1 .or. zr /= 1) error stop "real x, rank of int64 y"
  call probe(i64_1, i32_2, zt, zr)
  if (zt /= 64 .or. zr /= 2) error stop "int64 x, rank 2 y"
  allocate(li(2), source=3_int32)
  allocate(lj(3), source=4_int64)
  allocate(lr(2, 2), source=1.5)
  call lift(li, li_out)
  call lift(lj, lj_out)
  call lift(lr, lr_out)
  if (any(li_out /= 4_int32)) error stop "lift int32"
  if (any(lj_out /= 5_int64)) error stop "lift int64"
  if (any(lr_out /= 2.5)) error stop "lift real"
end program
