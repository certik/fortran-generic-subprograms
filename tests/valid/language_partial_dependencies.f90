! TEST-RULE: C802 R704 R708 R831 7.3.2.1 8.2 15.6.2.4
! TEST-REQUIRES: real32 real64
! Draft 8.2 NOTE 1: X contributes two kinds and three ranks, while Y
! independently contributes two kinds but takes its rank from X: 12 specifics.
! TYPEOF(X) with an independent generic RANK makes Y rank-generic. Dependent
! entities may share a declaration and may be OPTIONAL.
module language_partial_dependencies_m
  use, intrinsic :: iso_fortran_env, only: real32, real64
  implicit none
contains
  generic subroutine note1(x, y, kx, ky, rx, sx, sy)
    real([real32, real64]), rank(1:3), intent(in) :: x
    real([real32, real64]), rank(rank(x)), intent(in) :: y
    integer, intent(out) :: kx, ky, rx
    real(real64), intent(out) :: sx, sy
    kx = kind(x)
    ky = kind(y)
    rx = rank(x)
    sx = real(sum(x), real64)
    sy = real(sum(y), real64)
  end subroutine

  generic subroutine independent_rank(x, y, k, r, total)
    type(integer, real), intent(in) :: x
    typeof(x), rank(0:2), intent(in) :: y
    integer, intent(out) :: k, r
    real(real64), intent(out) :: total
    k = kind(y)
    r = rank(y)
    select generic type (x)
    declared type is (integer)
      select generic rank (y)
      rank (0)
        total = real(x + y, real64)
      rank (1)
        total = real(x + sum(y), real64)
      rank (2)
        total = real(x + sum(y), real64)
      end select
    declared type is (real)
      select generic rank (y)
      rank (0)
        total = real(x + y, real64)
      rank (1)
        total = real(x + sum(y), real64)
      rank (2)
        total = real(x + sum(y), real64)
      end select
    end select
  end subroutine

  generic function combine(x, first, second, maybe) result(y)
    type(integer, real), intent(in) :: x
    typeof(x), intent(in) :: first, second
    typeof(x), intent(in), optional :: maybe
    typeof(x) :: y
    y = x + first + second
    if (present(maybe)) y = y + maybe
  end function
end module

program language_partial_dependencies_p
  use, intrinsic :: iso_fortran_env, only: real32, real64
  use language_partial_dependencies_m
  implicit none
  real(real32) :: x32_1(2), x32_2(2, 1), x32_3(2, 1, 1)
  real(real64) :: x64_1(2), x64_2(2, 1), x64_3(2, 1, 1)
  integer :: kx, ky, r
  real(real64) :: sx, sy, total
  integer :: i1(2), i2(1, 2)
  real :: r1(2), r2(1, 2)

  if (real32 < 0 .or. real64 < 0) error stop "need real32 and real64"
  x32_1 = 1.0_real32
  x32_2 = 2.0_real32
  x32_3 = 3.0_real32
  x64_1 = 4.0_real64
  x64_2 = 5.0_real64
  x64_3 = 6.0_real64

  call note1(x32_1, x32_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real32, real32, 1, 2.0_real64, 2.0_real64)
  call note1(x32_1, x64_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real32, real64, 1, 2.0_real64, 8.0_real64)
  call note1(x32_2, x32_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real32, real32, 2, 4.0_real64, 4.0_real64)
  call note1(x32_2, x64_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real32, real64, 2, 4.0_real64, 10.0_real64)
  call note1(x32_3, x32_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real32, real32, 3, 6.0_real64, 6.0_real64)
  call note1(x32_3, x64_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real32, real64, 3, 6.0_real64, 12.0_real64)
  call note1(x64_1, x32_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real64, real32, 1, 8.0_real64, 2.0_real64)
  call note1(x64_1, x64_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real64, real64, 1, 8.0_real64, 8.0_real64)
  call note1(x64_2, x32_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real64, real32, 2, 10.0_real64, 4.0_real64)
  call note1(x64_2, x64_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real64, real64, 2, 10.0_real64, 10.0_real64)
  call note1(x64_3, x32_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real64, real32, 3, 12.0_real64, 6.0_real64)
  call note1(x64_3, x64_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, real64, real64, 3, 12.0_real64, 12.0_real64)

  i1 = [2, 3]
  i2 = reshape([1, 2], [1, 2])
  r1 = [1.5, 2.5]
  r2 = reshape([2.0, 3.0], [1, 2])
  call independent_rank(5, 2, kx, r, total)
  call check_rank(kx, r, total, kind(0), 0, 7.0_real64)
  call independent_rank(5, i1, kx, r, total)
  call check_rank(kx, r, total, kind(0), 1, 10.0_real64)
  call independent_rank(5, i2, kx, r, total)
  call check_rank(kx, r, total, kind(0), 2, 8.0_real64)
  call independent_rank(0.5, 1.5, kx, r, total)
  call check_rank(kx, r, total, kind(0.0), 0, 2.0_real64)
  call independent_rank(0.5, r1, kx, r, total)
  call check_rank(kx, r, total, kind(0.0), 1, 4.5_real64)
  call independent_rank(0.5, r2, kx, r, total)
  call check_rank(kx, r, total, kind(0.0), 2, 5.5_real64)

  if (combine(1, 2, 3) /= 6) error stop "dependent optional integer absent"
  if (combine(1, 2, 3, 4) /= 10) error stop "dependent optional integer present"
  if (combine(1.0, 2.0, 3.0) /= 6.0) error stop "dependent optional real absent"
  if (combine(1.0, 2.0, 3.0, 4.0) /= 10.0) error stop "dependent optional real present"
contains
  subroutine check_note(akx, aky, ar, asx, asy, ekx, eky, er, esx, esy)
    integer, intent(in) :: akx, aky, ar, ekx, eky, er
    real(real64), intent(in) :: asx, asy, esx, esy
    if (akx /= ekx .or. aky /= eky .or. ar /= er .or. asx /= esx .or. asy /= esy) &
      error stop "partial dependency note"
  end subroutine

  subroutine check_rank(ak, ar, av, ek, er, ev)
    integer, intent(in) :: ak, ar, ek, er
    real(real64), intent(in) :: av, ev
    if (ak /= ek .or. ar /= er .or. av /= ev) error stop "dependent rank"
  end subroutine
end program
