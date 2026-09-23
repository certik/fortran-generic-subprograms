! TEST-RULE: R704 R705 R831 8.1 C819 10.1.11 10.1.12 15.6.2.4
! TEST-REQUIRES: real64
! TEST-PASS: language_specification_processing
! Attributes supplied by DIMENSION, ALLOCATABLE, POINTER, and INTENT
! statements are combined with generic/dependent type declarations. Constant
! and specification expressions depend on the interpreted kind, rank, and
! shape of a generic dummy.
module language_specification_processing_m
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
contains
  generic subroutine separate_attributes(x, a, p)
    type(integer, real) :: x
    typeof(x) :: a, p
    dimension :: x(:), a(:), p(:)
    intent(in) :: x
    intent(out) :: a
    intent(inout) :: p
    allocatable :: a
    pointer :: p
    a = x
    p = x + x
  end subroutine

  generic subroutine property_probe(x, k, r, extent, total)
    type(integer, real), rank(1:2), intent(in) :: x
    integer, intent(out) :: k, r, extent
    real(real64), intent(out) :: total
    integer, parameter :: specific_kind = kind(x)
    integer, parameter :: specific_rank = rank(x)
    k = specific_kind
    r = specific_rank
    select generic type (x)
    declared type is (integer)
      block
        integer(kind=specific_kind) :: copy(size(x))
        copy = reshape(x, [size(x)])
        total = real(sum(copy), real64)
      end block
    declared type is (real)
      block
        real(kind=specific_kind) :: copy(size(x))
        copy = reshape(x, [size(x)])
        total = real(sum(copy), real64)
      end block
    end select
    select generic rank (x)
    rank (1)
      block
        integer :: work(size(x, 1) + specific_rank)
        work = 1
        extent = size(work)
      end block
    rank (2)
      block
        integer :: work(size(x, 1) + size(x, 2) + specific_rank)
        work = 1
        extent = size(work)
      end block
    end select
  end subroutine
end module

program language_specification_processing_p
  use, intrinsic :: iso_fortran_env, only: real64
  use language_specification_processing_m
  implicit none
  integer :: ix(3), im(1, 2)
  real :: rx(3), rm(1, 2)
  integer, target :: itarget(3)
  real, target :: rtarget(3)
  integer, pointer :: ip(:)
  real, pointer :: rp(:)
  integer, allocatable :: ia(:)
  real, allocatable :: ra(:)
  integer :: k, r, extent
  real(real64) :: total

  ix = [1, 2, 3]
  rx = [1.5, 2.5, 3.5]
  itarget = 0
  rtarget = 0.0
  ip => itarget
  rp => rtarget
  call separate_attributes(ix, ia, ip)
  call separate_attributes(rx, ra, rp)
  if (.not. allocated(ia)) error stop "separate allocatable integer allocation"
  if (.not. allocated(ra)) error stop "separate allocatable real allocation"
  if (any(ia /= ix)) error stop "separate allocatable integer"
  if (any(ra /= rx)) error stop "separate allocatable real"
  if (.not. associated(ip, itarget) .or. any(itarget /= 2*ix)) error stop "separate pointer integer"
  if (.not. associated(rp, rtarget) .or. any(rtarget /= 2.0*rx)) error stop "separate pointer real"

  im = reshape([4, 5], [1, 2])
  rm = reshape([4.5, 5.5], [1, 2])
  call property_probe(ix, k, r, extent, total)
  call check(k, r, extent, total, kind(ix), 1, 4, 6.0_real64)
  call property_probe(im, k, r, extent, total)
  call check(k, r, extent, total, kind(im), 2, 5, 9.0_real64)
  call property_probe(rx, k, r, extent, total)
  call check(k, r, extent, total, kind(rx), 1, 4, 7.5_real64)
  call property_probe(rm, k, r, extent, total)
  call check(k, r, extent, total, kind(rm), 2, 5, 10.0_real64)
  print '(a)', 'TEST-PASS: language_specification_processing'
contains
  subroutine check(ak, ar, ae, av, ek, er, ee, ev)
    integer, intent(in) :: ak, ar, ae, ek, er, ee
    real(real64), intent(in) :: av, ev
    if (ak /= ek .or. ar /= er .or. ae /= ee .or. av /= ev) error stop "property probe"
  end subroutine
end program
