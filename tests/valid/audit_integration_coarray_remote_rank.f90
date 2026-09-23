! TEST-RULE: 8.5.6 9.8.1.2 9.8.3.2 11.7.1 11.7.3 15.5.2.7 15.5.2.9 15.6.2.4
! TEST-IMAGES: 2
! TEST-PASS: audit-integration-coarray-remote-rank
! Nonallocatable coarray dummies that are both type- and rank-generic read
! the peer image's scalar, vector, and matrix data through the dummy.
! Allocatable coarray dummies with generic rank keep the actual's bounds and
! cobounds (deferred shape), and every image reallocates them collectively
! inside the generated specific. The rank-zero-only multi-image case is
! valid/integration_coarray_multi_image.f90. Each image prints the marker.
module audit_integration_coarray_remote_rank_m
  implicit none
  private
  public :: remote_sum, inspect_shared, regrow_shared
contains
  generic function remote_sum(x, image) result(total)
    type(integer, real), intent(in), rank(0:2) :: x[*]
    integer, intent(in) :: image
    real :: total
    select generic rank (x)
    rank (0)
      total = real(x[image])
    rank (1)
      total = real(sum(x(:)[image]))
    rank (2)
      total = real(sum(x(:, :)[image])) + real(x(size(x, 1), size(x, 2))[image])
    end select
  end function

  generic subroutine inspect_shared(x, lower, colower, code)
    type(integer, real), allocatable, intent(in), rank(1:2) :: x[:]
    integer, intent(in) :: lower(:), colower
    integer, intent(out) :: code
    if (.not. allocated(x)) error stop "allocatable coarray dummy allocation status"
    if (size(lower) /= rank(x)) error stop "generated allocatable coarray rank"
    if (any(lbound(x) /= lower)) error stop "allocatable coarray dummy lower bounds"
    if (lcobound(x, 1) /= colower) error stop "allocatable coarray dummy lower cobound"
    if (ucobound(x, 1) /= colower + num_images() - 1) error stop "allocatable coarray upper cobound"
    select generic type (x)
    declared type is (integer)
      code = 100*rank(x) + size(x)
    declared type is (real)
      code = 200*rank(x) + size(x)
    end select
  end subroutine

  generic subroutine regrow_shared(x, n)
    type(integer, real), allocatable, intent(inout), rank(1:2) :: x[:]
    integer, intent(in) :: n
    if (allocated(x)) deallocate(x)
    select generic rank (x)
    rank (1)
      allocate(x(0:n - 1)[5:*])
    rank (2)
      allocate(x(n, -1:0)[5:*])
    end select
    x = this_image()
  end subroutine
end module

program audit_integration_coarray_remote_rank_p
  use audit_integration_coarray_remote_rank_m
  implicit none
  integer :: si[*]
  real :: sr[*]
  integer :: vi(3)[*]
  real :: vr(2)[*]
  integer :: mi(2, 2)[*]
  real :: mr(1, 3)[*]
  integer, allocatable :: ai(:)[:], am(:, :)[:]
  real, allocatable :: ar(:)[:], amr(:, :)[:]
  integer :: me, peer, code, peer_cosubscript

  if (num_images() /= 2) error stop "requires exactly two images"
  me = this_image()
  peer = 3 - me
  si = 10*me
  sr = 1.5*me
  vi = [1, 2, 3]*me
  vr = [0.5, 0.25]*me
  mi = reshape([1, 2, 3, 4], [2, 2])*me
  mr = reshape([1.0, 2.0, 3.0], [1, 3])*me
  sync all
  if (remote_sum(si, peer) /= real(10*peer)) error stop "remote integer scalar"
  if (remote_sum(sr, peer) /= 1.5*peer) error stop "remote real scalar"
  if (remote_sum(vi, peer) /= real(6*peer)) error stop "remote integer vector"
  if (remote_sum(vr, peer) /= 0.75*peer) error stop "remote real vector"
  if (remote_sum(mi, peer) /= real(14*peer)) error stop "remote integer matrix"
  if (remote_sum(mr, peer) /= 9.0*peer) error stop "remote real matrix"
  sync all

  allocate(ai(-2:0)[3:*], ar(4:5)[3:*], am(0:1, 2:3)[3:*], amr(1, 1)[3:*])
  call inspect_shared(ai, [-2], 3, code)
  if (code /= 103) error stop "integer vector allocatable coarray descriptor"
  call inspect_shared(ar, [4], 3, code)
  if (code /= 202) error stop "real vector allocatable coarray descriptor"
  call inspect_shared(am, [0, 2], 3, code)
  if (code /= 204) error stop "integer matrix allocatable coarray descriptor"
  call inspect_shared(amr, [1, 1], 3, code)
  if (code /= 401) error stop "real matrix allocatable coarray descriptor"

  call regrow_shared(ai, 4)
  call regrow_shared(ar, 2)
  call regrow_shared(am, 3)
  call regrow_shared(amr, 1)
  if (any(lbound(ai) /= [0]) .or. any(ubound(ai) /= [3])) error stop "reallocated integer vector"
  if (any(lbound(am) /= [1, -1]) .or. any(ubound(am) /= [3, 0])) then
    error stop "reallocated integer matrix"
  end if
  if (lcobound(ai, 1) /= 5 .or. lcobound(amr, 1) /= 5) error stop "reallocated cobounds"
  sync all
  peer_cosubscript = lcobound(ai, 1) + peer - 1
  if (any(ai(:)[peer_cosubscript] /= peer)) error stop "remote reallocated integer vector"
  if (any(ar(:)[peer_cosubscript] /= real(peer))) error stop "remote reallocated real vector"
  if (any(am(:, :)[peer_cosubscript] /= peer)) error stop "remote reallocated integer matrix"
  if (any(amr(:, :)[peer_cosubscript] /= real(peer))) error stop "remote reallocated real matrix"
  if (size(am(:, :)[peer_cosubscript]) /= 6) error stop "remote reallocated extent"
  sync all
  print '(a)', 'TEST-PASS: audit-integration-coarray-remote-rank'
end program
