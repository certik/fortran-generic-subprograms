! TEST-RULE: C826 C875 8.5.6 8.5.17 15.5.2.9 15.6.2.4 17.9.116 17.9.129 17.9.227 17.9.235 17.10.2.24
! TEST-PASS: audit-integration-coarray-rank13-corank2
! Rank 13 with corank 2 is the literal portable boundary: 13 + 2 = 15 (C826).
! The 17.10.2.24 example for a processor with exactly the minimum limits
! (MAX_RANK() = 15, MAX_RANK(1) = 14, MAX_RANK(15) = 0) keeps rank plus
! corank at 15, so MAX_RANK(2) >= 13 and C875 is met without the
! extended-rank-limit or literal-rank-limit readings. Every declared
! rank specific (0, 1, 2, 7, 12, 13) and both type specifics at the boundary
! are called with coarray actuals whose nonunit lower bounds, extents, and
! element order are checked, together with the dummy's cobounds and
! cosubscripts. The case also runs on one image.
module audit_integration_coarray_rank13_corank2_m
  implicit none
  private
  public :: verify, boundary_total
contains
  generic function verify(x, expected_shape) result(code)
    integer, intent(in), rank(0, 1, 2, 7, 12, 13) :: x[2, *]
    integer, intent(in) :: expected_shape(:)
    integer :: code
    integer, allocatable :: flat(:)
    integer :: i
    if (any(lcobound(x) /= [1, 1]) .or. ucobound(x, 1) /= 2) error stop "dummy cobounds"
    if (ucobound(x, 2) /= (num_images() + 1)/2) error stop "dummy final cobound"
    if (image_index(x, this_image(x)) /= this_image()) error stop "dummy cosubscripts"
    select generic rank (x)
    rank (0)
      if (size(expected_shape) /= 0) error stop "scalar expected shape"
      code = x
    rank default
      if (size(expected_shape) /= rank(x)) error stop "generated rank"
      if (any(shape(x) /= expected_shape)) error stop "assumed shape"
      if (any(lbound(x) /= 1)) error stop "assumed-shape lower bounds"
      flat = reshape(x, [size(x)])
      code = sum([(i*flat(i), i=1, size(flat))])
    end select
  end function

  generic function boundary_total(x) result(total)
    type(integer, real), intent(in), rank(13:13) :: x[2, *]
    real :: total
    if (any(shape(x) /= [1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 3])) error stop "boundary shape"
    select generic type (x)
    declared type is (integer)
      total = real(sum(x))
    declared type is (real)
      total = sum(x) + 0.5
    end select
  end function
end module

program audit_integration_coarray_rank13_corank2_p
  use audit_integration_coarray_rank13_corank2_m
  implicit none
  integer :: s[2, *]
  integer :: v(0:2)[2, *]
  integer :: m(0:1, -1:1)[2, *]
  integer :: r7(1, 2, 1, 1, 1, 1, 2)[2, *]
  integer :: r12(2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2)[2, *]
  integer :: r13(2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2)[2, *]
  integer :: b13(1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 3)[2, *]
  real :: q13(1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 3)[2, *]
  integer :: none(0)
  integer :: i

  s = 41
  v = [3, 5, 7]
  m = reshape([(10 + i, i=1, 6)], [2, 3])
  r7 = reshape([(20 + i, i=1, 4)], shape(r7))
  r12 = reshape([(30 + i, i=1, 4)], shape(r12))
  r13 = reshape([(40 + i, i=1, 8)], shape(r13))
  b13 = reshape([(i, i=1, 6)], shape(b13))
  q13 = reshape([(0.25*i, i=1, 6)], shape(q13))
  sync all

  if (verify(s, none) /= 41) error stop "rank-zero specific"
  if (verify(v, [3]) /= 1*3 + 2*5 + 3*7) error stop "rank-one specific"
  if (verify(m, [2, 3]) /= sum([(i*(10 + i), i=1, 6)])) error stop "rank-two specific"
  if (verify(r7, [1, 2, 1, 1, 1, 1, 2]) /= sum([(i*(20 + i), i=1, 4)])) then
    error stop "rank-seven specific"
  end if
  if (verify(r12, [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2]) /= sum([(i*(30 + i), i=1, 4)])) then
    error stop "rank-twelve specific"
  end if
  if (verify(r13, [2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2]) /= sum([(i*(40 + i), i=1, 8)])) then
    error stop "rank-thirteen specific"
  end if
  if (boundary_total(b13) /= 21.0) error stop "integer boundary specific"
  if (boundary_total(q13) /= 5.75) error stop "real boundary specific"
  sync all
  print '(a)', 'TEST-PASS: audit-integration-coarray-rank13-corank2'
end program
