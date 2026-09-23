! TEST-RULE: C1517 15.4.3.4.5 15.5.2.6 15.5.2.7 15.5.2.8 15.5.2.13 15.5.5.2 15.6.2.4
! TEST-PASS: audit-integration-alloc-pointer-optional
! Two generated families share one name: an allocatable family and a
! non-INTENT(IN) pointer family. Every same-TKR pair is distinguishable by
! the allocatable/pointer rule of 15.4.3.4.5 p6, and each actual selects the
! family whose attribute it has. A separate INTENT(IN) pointer family
! accepts a nonpointer TARGET actual and becomes associated with it
! (15.5.2.8 p2). Optional nongeneric dummies are forwarded while absent,
! and unallocated or disassociated actuals make an optional nonallocatable,
! nonpointer dummy not present (15.5.2.13), unlike an optional allocatable
! dummy.
module audit_integration_alloc_pointer_optional_m
  implicit none
  private
  public :: place, bump_target, report, forward, remember, remember_twice
contains
  generic subroutine place(x, code)
    type(integer, real), allocatable, intent(inout), rank(0:1) :: x
    integer, intent(out) :: code
    if (allocated(x)) deallocate(x)
    select generic rank (x)
    rank (0)
      allocate(x)
    rank (1)
      allocate(x(2))
    end select
    x = 1
    select generic type (x)
    declared type is (integer)
      code = 100 + rank(x)
    declared type is (real)
      code = 110 + rank(x)
    end select
  end subroutine

  generic subroutine place(x, code)
    type(integer, real), pointer, intent(inout), rank(0:1) :: x
    integer, intent(out) :: code
    select generic rank (x)
    rank (0)
      allocate(x)
    rank (1)
      allocate(x(3))
    end select
    x = 2
    select generic type (x)
    declared type is (integer)
      code = 200 + rank(x)
    declared type is (real)
      code = 210 + rank(x)
    end select
  end subroutine

  generic subroutine bump_target(x, amount)
    type(integer, real), pointer, intent(in), rank(0:1) :: x
    integer, intent(in) :: amount
    if (.not. associated(x)) error stop "INTENT(IN) pointer not associated"
    x = x + amount
  end subroutine

  generic function report(x, scale, offset) result(r)
    type(integer, real), intent(in), rank(0:1) :: x
    integer, intent(in), optional :: scale
    integer, intent(in), optional :: offset
    real :: r
    r = sum([real(x)])
    if (present(scale)) r = r*scale
    if (present(offset)) r = r + offset
  end function

  generic function forward(x, scale, offset) result(r)
    type(integer, real), intent(in), rank(0:1) :: x
    integer, intent(in), optional :: scale
    integer, intent(in), optional :: offset
    real :: r
    r = report(x, scale, offset)
  end function

  generic subroutine remember(x, store)
    type(integer, real), intent(in), rank(0:1) :: x
    real, allocatable, intent(inout), optional :: store(:)
    if (.not. present(store)) return
    if (allocated(store)) then
      store = [store, real(x)]
    else
      store = [real(x)]
    end if
  end subroutine

  generic subroutine remember_twice(x, store)
    type(integer, real), intent(in), rank(0:1) :: x
    real, allocatable, intent(inout), optional :: store(:)
    call remember(x, store)
    call remember(x, store)
  end subroutine
end module

program audit_integration_alloc_pointer_optional_p
  use audit_integration_alloc_pointer_optional_m
  implicit none
  integer, allocatable :: ia, iav(:)
  real, allocatable :: ra, rav(:)
  integer, pointer :: ip, ipv(:)
  real, pointer :: rp, rpv(:)
  integer, target :: it, itv(5)
  real, target :: rt, rtv(4)
  integer, allocatable :: missing_scale
  integer, pointer :: missing_offset
  integer, target :: offset_target
  real, allocatable :: log(:)
  integer :: code

  call place(ia, code)
  if (code /= 100 .or. .not. allocated(ia) .or. ia /= 1) error stop "integer scalar allocatable family"
  call place(iav, code)
  if (code /= 101 .or. size(iav) /= 2 .or. any(iav /= 1)) error stop "integer vector allocatable family"
  call place(ra, code)
  if (code /= 110 .or. ra /= 1.0) error stop "real scalar allocatable family"
  call place(rav, code)
  if (code /= 111 .or. size(rav) /= 2 .or. any(rav /= 1.0)) error stop "real vector allocatable family"
  call place(iav, code)
  if (code /= 101 .or. size(iav) /= 2) error stop "allocatable family reallocation"

  nullify(ip, ipv, rp, rpv)
  call place(ip, code)
  if (code /= 200 .or. .not. associated(ip) .or. ip /= 2) error stop "integer scalar pointer family"
  call place(ipv, code)
  if (code /= 201 .or. size(ipv) /= 3 .or. any(ipv /= 2)) error stop "integer vector pointer family"
  call place(rp, code)
  if (code /= 210 .or. rp /= 2.0) error stop "real scalar pointer family"
  call place(rpv, code)
  if (code /= 211 .or. size(rpv) /= 3 .or. any(rpv /= 2.0)) error stop "real vector pointer family"
  deallocate(ip, ipv, rp, rpv)

  it = 10
  itv = [1, 2, 3, 4, 5]
  rt = 0.5
  rtv = [1.0, 2.0, 3.0, 4.0]
  call bump_target(it, 5)
  if (it /= 15) error stop "integer scalar TARGET actual association"
  call bump_target(itv(1:5:2), 10)
  if (any(itv /= [11, 2, 13, 4, 15])) error stop "integer strided TARGET association"
  call bump_target(rt, 2)
  if (rt /= 2.5) error stop "real scalar TARGET actual association"
  call bump_target(rtv(2:3), 1)
  if (any(rtv /= [1.0, 3.0, 4.0, 4.0])) error stop "real section TARGET association"
  ip => itv(2)
  call bump_target(ip, 100)
  if (itv(2) /= 102) error stop "pointer actual to INTENT(IN) pointer"

  if (report(3) /= 3.0) error stop "all optionals absent"
  if (report(3, 2) /= 6.0) error stop "positional optional present"
  if (report([1.5, 2.5], offset=5) /= 9.0) error stop "keyword optional present"
  if (forward(3) /= 3.0) error stop "forwarded absent optionals"
  if (forward([1, 2], 2) /= 6.0) error stop "forwarded present scale"
  if (forward(0.5, offset=1) /= 1.5) error stop "forwarded present offset only"
  nullify(missing_offset)
  if (report(4, missing_scale) /= 4.0) error stop "unallocated actual is not present"
  if (report([2.0, 3.0], offset=missing_offset) /= 5.0) then
    error stop "disassociated actual is not present"
  end if
  if (forward(4, missing_scale, missing_offset) /= 4.0) then
    error stop "forwarded not-present actuals"
  end if
  allocate(missing_scale, source=3)
  offset_target = 7
  missing_offset => offset_target
  if (report(4, missing_scale) /= 12.0) error stop "allocated actual is present"
  if (forward([1.0, 1.0], missing_scale, missing_offset) /= 13.0) then
    error stop "forwarded allocated and associated actuals"
  end if

  call remember(5)
  call remember(5, log)
  if (.not. allocated(log)) error stop "unallocated actual to optional allocatable is present"
  if (size(log) /= 1 .or. log(1) /= 5.0) error stop "first remembered value"
  call remember([1.5, 2.5], log)
  if (size(log) /= 3 .or. any(log /= [5.0, 1.5, 2.5])) error stop "remembered vector"
  call remember_twice(8)
  call remember_twice(8, log)
  if (size(log) /= 5 .or. any(log(4:5) /= 8.0)) error stop "forwarded optional allocatable"
  print '(a)', 'TEST-PASS: audit-integration-alloc-pointer-optional'
end program
