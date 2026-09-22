! TEST-RULE: C802 R704 R705 R708 R831 8.2 15.6.2.4
! TEST-REQUIRES: int32 int64 real64
! 15.6.2.4 NOTE 2, made runnable.
! PROBE executes all 6 x 6 independent combinations. Z takes its declared
! type and kind from X, its rank and shape from Y, and values from X.
! LIFT executes all six dependent type/kind/rank combinations.
module standard_note_shapes_m
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none

  interface inspect_z
    module procedure inspect_i32, inspect_i64, inspect_real
  end interface
contains
  subroutine inspect_i32(z, zt, zk, zr, ze1, ze2, zv)
    integer(int32), intent(in) :: z(..)
    integer, intent(out) :: zt, zk, zr, ze1, ze2
    real(real64), intent(out) :: zv
    zt = 32
    zk = kind(z)
    zr = rank(z)
    select rank (z)
    rank (1)
      ze1 = size(z, 1)
      ze2 = 0
      zv = real(sum(z), real64)
    rank (2)
      ze1 = size(z, 1)
      ze2 = size(z, 2)
      zv = real(sum(z), real64)
    rank default
      error stop "inspect int32 rank"
    end select
  end subroutine

  subroutine inspect_i64(z, zt, zk, zr, ze1, ze2, zv)
    integer(int64), intent(in) :: z(..)
    integer, intent(out) :: zt, zk, zr, ze1, ze2
    real(real64), intent(out) :: zv
    zt = 64
    zk = kind(z)
    zr = rank(z)
    select rank (z)
    rank (1)
      ze1 = size(z, 1)
      ze2 = 0
      zv = real(sum(z), real64)
    rank (2)
      ze1 = size(z, 1)
      ze2 = size(z, 2)
      zv = real(sum(z), real64)
    rank default
      error stop "inspect int64 rank"
    end select
  end subroutine

  subroutine inspect_real(z, zt, zk, zr, ze1, ze2, zv)
    real, intent(in) :: z(..)
    integer, intent(out) :: zt, zk, zr, ze1, ze2
    real(real64), intent(out) :: zv
    zt = 1
    zk = kind(z)
    zr = rank(z)
    select rank (z)
    rank (1)
      ze1 = size(z, 1)
      ze2 = 0
      zv = real(sum(z), real64)
    rank (2)
      ze1 = size(z, 1)
      ze2 = size(z, 2)
      zv = real(sum(z), real64)
    rank default
      error stop "inspect real rank"
    end select
  end subroutine

  generic subroutine probe(x, y, zt, zk, zr, ze1, ze2, zv)
    type(integer([int32, int64]), real), rank(1:2), intent(in) :: x
    type(integer([int32, int64]), real), rank(1:2), intent(in) :: y
    integer, intent(out) :: zt, zk, zr, ze1, ze2
    real(real64), intent(out) :: zv
    typeof(x), allocatable, rank(rank(y)) :: z
    select generic rank (y)
    rank (1)
      allocate(z(size(y, 1)))
    rank (2)
      allocate(z(size(y, 1), size(y, 2)))
    end select
    z = sum(x)
    call inspect_z(z, zt, zk, zr, ze1, ze2, zv)
  end subroutine

  generic subroutine lift(x, y)
    type(integer([int32, int64]), real), rank(1:2), allocatable, intent(in) :: x
    typeof(x), rank(rank(x)), allocatable, intent(out) :: y
    y = x
    y = y + 1
  end subroutine
end module

program standard_note_shapes_p
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  use standard_note_shapes_m
  implicit none
  integer(int32) :: i32_1(2), i32_2(2, 2)
  integer(int64) :: i64_1(2), i64_2(2, 2)
  real :: r_1(2), r_2(2, 2)
  integer :: zt, zk, zr, ze1, ze2
  real(real64) :: zv
  integer(int32), allocatable :: li32_1(:), li32_2(:, :)
  integer(int32), allocatable :: lo32_1(:), lo32_2(:, :)
  integer(int64), allocatable :: li64_1(:), li64_2(:, :)
  integer(int64), allocatable :: lo64_1(:), lo64_2(:, :)
  real, allocatable :: lr_1(:), lr_2(:, :), lro_1(:), lro_2(:, :)

  if (int32 < 0 .or. int64 < 0) error stop "need int32 and int64"
  i32_1 = [1_int32, 2_int32]
  i32_2 = reshape([1_int32, 2_int32, 3_int32, 4_int32], [2, 2])
  i64_1 = [5_int64, 6_int64]
  i64_2 = reshape([2_int64, 4_int64, 6_int64, 8_int64], [2, 2])
  r_1 = [1.5, 2.5]
  r_2 = reshape([0.5, 1.5, 2.5, 3.5], [2, 2])

  call probe(i32_1, i32_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 1, 2, 0, 6.0_real64, "i32r1/i32r1")
  call probe(i32_1, i32_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 2, 2, 2, 12.0_real64, "i32r1/i32r2")
  call probe(i32_1, i64_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 1, 2, 0, 6.0_real64, "i32r1/i64r1")
  call probe(i32_1, i64_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 2, 2, 2, 12.0_real64, "i32r1/i64r2")
  call probe(i32_1, r_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 1, 2, 0, 6.0_real64, "i32r1/realr1")
  call probe(i32_1, r_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 2, 2, 2, 12.0_real64, "i32r1/realr2")

  call probe(i32_2, i32_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 1, 2, 0, 20.0_real64, "i32r2/i32r1")
  call probe(i32_2, i32_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 2, 2, 2, 40.0_real64, "i32r2/i32r2")
  call probe(i32_2, i64_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 1, 2, 0, 20.0_real64, "i32r2/i64r1")
  call probe(i32_2, i64_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 2, 2, 2, 40.0_real64, "i32r2/i64r2")
  call probe(i32_2, r_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 1, 2, 0, 20.0_real64, "i32r2/realr1")
  call probe(i32_2, r_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 32, int32, 2, 2, 2, 40.0_real64, "i32r2/realr2")

  call probe(i64_1, i32_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 1, 2, 0, 22.0_real64, "i64r1/i32r1")
  call probe(i64_1, i32_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 2, 2, 2, 44.0_real64, "i64r1/i32r2")
  call probe(i64_1, i64_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 1, 2, 0, 22.0_real64, "i64r1/i64r1")
  call probe(i64_1, i64_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 2, 2, 2, 44.0_real64, "i64r1/i64r2")
  call probe(i64_1, r_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 1, 2, 0, 22.0_real64, "i64r1/realr1")
  call probe(i64_1, r_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 2, 2, 2, 44.0_real64, "i64r1/realr2")

  call probe(i64_2, i32_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 1, 2, 0, 40.0_real64, "i64r2/i32r1")
  call probe(i64_2, i32_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 2, 2, 2, 80.0_real64, "i64r2/i32r2")
  call probe(i64_2, i64_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 1, 2, 0, 40.0_real64, "i64r2/i64r1")
  call probe(i64_2, i64_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 2, 2, 2, 80.0_real64, "i64r2/i64r2")
  call probe(i64_2, r_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 1, 2, 0, 40.0_real64, "i64r2/realr1")
  call probe(i64_2, r_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 64, int64, 2, 2, 2, 80.0_real64, "i64r2/realr2")

  call probe(r_1, i32_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 1, 2, 0, 8.0_real64, "realr1/i32r1")
  call probe(r_1, i32_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 2, 2, 2, 16.0_real64, "realr1/i32r2")
  call probe(r_1, i64_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 1, 2, 0, 8.0_real64, "realr1/i64r1")
  call probe(r_1, i64_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 2, 2, 2, 16.0_real64, "realr1/i64r2")
  call probe(r_1, r_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 1, 2, 0, 8.0_real64, "realr1/realr1")
  call probe(r_1, r_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 2, 2, 2, 16.0_real64, "realr1/realr2")

  call probe(r_2, i32_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 1, 2, 0, 16.0_real64, "realr2/i32r1")
  call probe(r_2, i32_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 2, 2, 2, 32.0_real64, "realr2/i32r2")
  call probe(r_2, i64_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 1, 2, 0, 16.0_real64, "realr2/i64r1")
  call probe(r_2, i64_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 2, 2, 2, 32.0_real64, "realr2/i64r2")
  call probe(r_2, r_1, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 1, 2, 0, 16.0_real64, "realr2/realr1")
  call probe(r_2, r_2, zt, zk, zr, ze1, ze2, zv)
  call verify(zt, zk, zr, ze1, ze2, zv, 1, kind(0.0), 2, 2, 2, 32.0_real64, "realr2/realr2")

  allocate(li32_1(2), source=[1_int32, 2_int32])
  allocate(li32_2(2, 2), source=reshape([1_int32, 2_int32, 3_int32, 4_int32], [2, 2]))
  allocate(li64_1(2), source=[5_int64, 6_int64])
  allocate(li64_2(2, 2), source=reshape([2_int64, 4_int64, 6_int64, 8_int64], [2, 2]))
  allocate(lr_1(2), source=[1.5, 2.5])
  allocate(lr_2(2, 2), source=reshape([0.5, 1.5, 2.5, 3.5], [2, 2]))
  call lift(li32_1, lo32_1)
  call lift(li32_2, lo32_2)
  call lift(li64_1, lo64_1)
  call lift(li64_2, lo64_2)
  call lift(lr_1, lro_1)
  call lift(lr_2, lro_2)
  if (.not. allocated(lo32_1)) error stop "lift int32 rank1 allocation"
  if (.not. allocated(lo32_2)) error stop "lift int32 rank2 allocation"
  if (.not. allocated(lo64_1)) error stop "lift int64 rank1 allocation"
  if (.not. allocated(lo64_2)) error stop "lift int64 rank2 allocation"
  if (.not. allocated(lro_1)) error stop "lift real rank1 allocation"
  if (.not. allocated(lro_2)) error stop "lift real rank2 allocation"
  if (any(lo32_1 /= li32_1 + 1_int32)) error stop "lift int32 rank1"
  if (any(lo32_2 /= li32_2 + 1_int32)) error stop "lift int32 rank2"
  if (any(lo64_1 /= li64_1 + 1_int64)) error stop "lift int64 rank1"
  if (any(lo64_2 /= li64_2 + 1_int64)) error stop "lift int64 rank2"
  if (any(lro_1 /= lr_1 + 1.0)) error stop "lift real rank1"
  if (any(lro_2 /= lr_2 + 1.0)) error stop "lift real rank2"
  if (kind(lo32_1) /= int32 .or. rank(lo32_1) /= 1) error stop "lift int32 rank1 metadata"
  if (kind(lo32_2) /= int32 .or. rank(lo32_2) /= 2) error stop "lift int32 rank2 metadata"
  if (kind(lo64_1) /= int64 .or. rank(lo64_1) /= 1) error stop "lift int64 rank1 metadata"
  if (kind(lo64_2) /= int64 .or. rank(lo64_2) /= 2) error stop "lift int64 rank2 metadata"
  if (kind(lro_1) /= kind(0.0) .or. rank(lro_1) /= 1) error stop "lift real rank1 metadata"
  if (kind(lro_2) /= kind(0.0) .or. rank(lro_2) /= 2) error stop "lift real rank2 metadata"
contains
  subroutine verify(at, ak, ar, ae1, ae2, av, et, ek, er, ee1, ee2, ev, label)
    integer, intent(in) :: at, ak, ar, ae1, ae2, et, ek, er, ee1, ee2
    real(real64), intent(in) :: av, ev
    character(len=*), intent(in) :: label
    if (at /= et .or. ak /= ek .or. ar /= er .or. ae1 /= ee1 .or. ae2 /= ee2 .or. av /= ev) then
      print *, "probe mismatch: ", label
      error stop "standard note probe"
    end if
  end subroutine
end program
