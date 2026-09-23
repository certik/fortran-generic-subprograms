! TEST-RULE: C802 R704 R708 R831 7.3.2.1 7.4.3.2 8.2 15.6.2.4
! TEST-PASS: language_partial_dependencies
! Draft 8.2 NOTE 1 with portable kinds: X contributes two kinds and three
! ranks, while Y independently contributes two kinds but takes its rank from
! X: 12 specifics. With no DEFAULT KIND statement in scope, KIND(0.0) is the
! single precision kind and KIND(0.0D0) the double precision kind, whose
! decimal precision is greater (7.4.3.2 p2, p6), so the two kinds are always
! distinct and no named-kind capability is needed. TYPEOF(X) with an
! independent generic RANK makes Y rank-generic. Dependent entities may share
! a declaration and may be OPTIONAL.
module language_partial_dependencies_m
  implicit none
  integer, parameter :: sp = kind(0.0), dp = kind(0.0d0)
contains
  generic subroutine note1(x, y, kx, ky, rx, sx, sy)
    real([sp, dp]), rank(1:3), intent(in) :: x
    real([sp, dp]), rank(rank(x)), intent(in) :: y
    integer, intent(out) :: kx, ky, rx
    real(dp), intent(out) :: sx, sy
    kx = kind(x)
    ky = kind(y)
    rx = rank(x)
    sx = real(sum(x), dp)
    sy = real(sum(y), dp)
  end subroutine

  generic subroutine independent_rank(x, y, k, r, total)
    type(integer, real), intent(in) :: x
    typeof(x), rank(0:2), intent(in) :: y
    integer, intent(out) :: k, r
    real(dp), intent(out) :: total
    k = kind(y)
    r = rank(y)
    select generic type (x)
    declared type is (integer)
      select generic rank (y)
      rank (0)
        total = real(x + y, dp)
      rank (1)
        total = real(x + sum(y), dp)
      rank (2)
        total = real(x + sum(y), dp)
      end select
    declared type is (real)
      select generic rank (y)
      rank (0)
        total = real(x + y, dp)
      rank (1)
        total = real(x + sum(y), dp)
      rank (2)
        total = real(x + sum(y), dp)
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
  use language_partial_dependencies_m
  implicit none
  real(sp) :: xs_1(2), xs_2(2, 1), xs_3(2, 1, 1)
  real(dp) :: xd_1(2), xd_2(2, 1), xd_3(2, 1, 1)
  integer :: kx, ky, r
  real(dp) :: sx, sy, total
  integer :: i1(2), i2(1, 2)
  real :: r1(2), r2(1, 2)

  if (sp == dp) error stop "default and double precision kinds coincide"
  xs_1 = 1.0_sp
  xs_2 = 2.0_sp
  xs_3 = 3.0_sp
  xd_1 = 4.0_dp
  xd_2 = 5.0_dp
  xd_3 = 6.0_dp

  call note1(xs_1, xs_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, sp, sp, 1, 2.0_dp, 2.0_dp)
  call note1(xs_1, xd_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, sp, dp, 1, 2.0_dp, 8.0_dp)
  call note1(xs_2, xs_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, sp, sp, 2, 4.0_dp, 4.0_dp)
  call note1(xs_2, xd_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, sp, dp, 2, 4.0_dp, 10.0_dp)
  call note1(xs_3, xs_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, sp, sp, 3, 6.0_dp, 6.0_dp)
  call note1(xs_3, xd_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, sp, dp, 3, 6.0_dp, 12.0_dp)
  call note1(xd_1, xs_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, dp, sp, 1, 8.0_dp, 2.0_dp)
  call note1(xd_1, xd_1, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, dp, dp, 1, 8.0_dp, 8.0_dp)
  call note1(xd_2, xs_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, dp, sp, 2, 10.0_dp, 4.0_dp)
  call note1(xd_2, xd_2, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, dp, dp, 2, 10.0_dp, 10.0_dp)
  call note1(xd_3, xs_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, dp, sp, 3, 12.0_dp, 6.0_dp)
  call note1(xd_3, xd_3, kx, ky, r, sx, sy)
  call check_note(kx, ky, r, sx, sy, dp, dp, 3, 12.0_dp, 12.0_dp)

  i1 = [2, 3]
  i2 = reshape([1, 2], [1, 2])
  r1 = [1.5, 2.5]
  r2 = reshape([2.0, 3.0], [1, 2])
  call independent_rank(5, 2, kx, r, total)
  call check_rank(kx, r, total, kind(0), 0, 7.0_dp)
  call independent_rank(5, i1, kx, r, total)
  call check_rank(kx, r, total, kind(0), 1, 10.0_dp)
  call independent_rank(5, i2, kx, r, total)
  call check_rank(kx, r, total, kind(0), 2, 8.0_dp)
  call independent_rank(0.5, 1.5, kx, r, total)
  call check_rank(kx, r, total, kind(0.0), 0, 2.0_dp)
  call independent_rank(0.5, r1, kx, r, total)
  call check_rank(kx, r, total, kind(0.0), 1, 4.5_dp)
  call independent_rank(0.5, r2, kx, r, total)
  call check_rank(kx, r, total, kind(0.0), 2, 5.5_dp)

  if (combine(1, 2, 3) /= 6) error stop "dependent optional integer absent"
  if (combine(1, 2, 3, 4) /= 10) error stop "dependent optional integer present"
  if (combine(1.0, 2.0, 3.0) /= 6.0) error stop "dependent optional real absent"
  if (combine(1.0, 2.0, 3.0, 4.0) /= 10.0) error stop "dependent optional real present"
  print '(a)', 'TEST-PASS: language_partial_dependencies'
contains
  subroutine check_note(akx, aky, ar, asx, asy, ekx, eky, er, esx, esy)
    integer, intent(in) :: akx, aky, ar, ekx, eky, er
    real(dp), intent(in) :: asx, asy, esx, esy
    if (akx /= ekx .or. aky /= eky .or. ar /= er .or. asx /= esx .or. asy /= esy) &
      error stop "partial dependency note"
  end subroutine

  subroutine check_rank(ak, ar, av, ek, er, ev)
    integer, intent(in) :: ak, ar, ek, er
    real(dp), intent(in) :: av, ev
    if (ak /= ek .or. ar /= er .or. av /= ev) error stop "dependent rank"
  end subroutine
end program
