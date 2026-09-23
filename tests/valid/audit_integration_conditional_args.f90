! TEST-RULE: C1541 C1542 C1543 C1544 C1545 C1548 15.5.2.3 15.5.2.13 15.5.5.2 15.6.2.4
! TEST-PASS: audit-integration-conditional-args
! Conditional arguments whose consequents agree in declared type, kind,
! rank, corank, and ALLOCATABLE attribute take part in generic resolution by
! those properties (15.5.2.3 p4). Variable consequents are definable for
! INTENT(INOUT) and allocatable dummies; .NIL. appears only for optional
! nongeneric dummies and makes them not present. The paired negatives are
! the integration_reject_conditional_* cases.
module audit_integration_conditional_args_m
  implicit none
  private
  public :: accumulate, describe, regrow
contains
  generic subroutine accumulate(x, step, scale)
    type(integer, real), intent(inout), rank(0:1) :: x
    typeof(x), intent(in) :: step
    integer, intent(in), optional :: scale
    if (present(scale)) then
      x = x + scale*step
    else
      x = x + step
    end if
  end subroutine

  generic function describe(x, weight) result(code)
    type(integer, real), intent(in), rank(0:1) :: x
    real, intent(in), optional :: weight
    integer :: code
    select generic type (x)
    declared type is (integer)
      code = 100
    declared type is (real)
      code = 200
    end select
    code = code + 10*rank(x)
    if (present(weight)) code = code + nint(weight)
  end function

  generic subroutine regrow(x, n)
    type(integer, real), allocatable, intent(inout) :: x(:)
    integer, intent(in) :: n
    if (allocated(x)) deallocate(x)
    allocate(x(n))
    x = n
  end subroutine
end module

program audit_integration_conditional_args_p
  use audit_integration_conditional_args_m
  implicit none
  integer :: first, second, third, k
  integer :: iv(3), iw(2)
  real :: rs, rt, rv(2), rw(4)
  integer, allocatable :: ia(:), ib(:)
  real, allocatable :: ra(:), rb(:)
  logical :: flag, scaled

  first = 1
  second = 2
  third = 3
  flag = .true.
  scaled = .false.
  call accumulate((flag ? first : second), 5, (scaled ? 2 : .nil.))
  if (first /= 6 .or. second /= 2) error stop "integer scalar first consequent"
  flag = .false.
  scaled = .true.
  call accumulate((flag ? first : second), 5, (scaled ? 2 : .nil.))
  if (first /= 6 .or. second /= 12) error stop "integer scalar second consequent"
  do k = 1, 3
    call accumulate((k == 1 ? first : k == 2 ? second : third), (k > 1 ? 10*k : 1))
  end do
  if (first /= 7 .or. second /= 32 .or. third /= 33) error stop "three-way consequents"

  iv = [1, 2, 3]
  iw = [10, 20]
  call accumulate((flag ? iv : iw), 1)
  if (any(iv /= [1, 2, 3]) .or. any(iw /= [11, 21])) error stop "integer rank-one consequent"
  rs = 0.5
  rt = 1.5
  rv = [1.0, 2.0]
  rw = [0.0, 0.0, 0.0, 0.0]
  call accumulate((.not. flag ? rs : rt), 2.0, (flag ? 3 : .nil.))
  if (rs /= 2.5 .or. rt /= 1.5) error stop "real scalar consequent"
  call accumulate((flag ? rv : rw), 0.25, (.not. flag ? 4 : .nil.))
  if (any(rv /= [1.0, 2.0]) .or. any(rw /= 1.0)) error stop "real rank-one consequent"

  if (describe((flag ? first : 2*second)) /= 100) error stop "integer scalar expression"
  if (describe((flag ? iv : iw)) /= 110) error stop "integer rank-one resolution"
  if (describe((flag ? rs : rt + 1.0), (flag ? 7.0 : .nil.)) /= 200) then
    error stop "real scalar resolution with absent weight"
  end if
  if (describe((flag ? rv : rw), (.not. flag ? 7.0 : .nil.)) /= 217) then
    error stop "real rank-one resolution with present weight"
  end if

  allocate(ia(1), ib(1), ra(1), rb(1))
  call regrow((flag ? ia : ib), 3)
  if (size(ia) /= 1 .or. size(ib) /= 3 .or. any(ib /= 3)) error stop "integer allocatable consequent"
  call regrow((.not. flag ? ra : rb), 2)
  if (size(ra) /= 2 .or. any(ra /= 2.0) .or. size(rb) /= 1) error stop "real allocatable consequent"
  deallocate(ib)
  call regrow((flag ? ia : ib), 4)
  if (.not. allocated(ib) .or. size(ib) /= 4) error stop "unallocated allocatable consequent"
  print '(a)', 'TEST-PASS: audit-integration-conditional-args'
end program
