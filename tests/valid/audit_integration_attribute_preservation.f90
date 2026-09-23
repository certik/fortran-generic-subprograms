! TEST-RULE: C866 C869 C870 C872 C1551 8.5.4 8.5.16 8.5.21 12.6.2.5 12.7.2 15.3.2.2 15.5.2.5 15.5.2.8 15.6.2.4 15.7
! TEST-PASS: audit-integration-attribute-preservation
! ASYNCHRONOUS, VOLATILE, and PROTECTED_TARGET survive specialization.
! Noncontiguous ASYNCHRONOUS and VOLATILE sections are associated with
! rank-generic assumed-shape dummies without copy-in/copy-out (C1551), and
! each generated specific completes its own asynchronous transfer with WAIT
! before returning, so no pending operation outlives the call. A
! PROTECTED_TARGET pointer dummy is allocated with SOURCE=, read by a PURE
! specific, and pointer-assigned, which are the permitted contexts; the
! forbidden contexts are the integration_reject_* attribute negatives.
module audit_integration_attribute_preservation_m
  implicit none
  private
  public :: async_round_trip, volatile_update, publish, observe, retarget
contains
  generic subroutine async_round_trip(x, unit, total)
    type(integer, real), asynchronous, intent(inout), rank(1:2) :: x
    integer, intent(in) :: unit
    real, intent(out) :: total
    integer :: id
    rewind(unit)
    write(unit, asynchronous='yes', id=id) x
    wait(unit, id=id)
    x = 0
    rewind(unit)
    read(unit, asynchronous='yes', id=id) x
    wait(unit, id=id)
    total = real(sum(x))
  end subroutine

  generic subroutine volatile_update(x, delta)
    type(integer, real), volatile, intent(inout), rank(0:1) :: x
    integer, intent(in) :: delta
    x = x + delta
  end subroutine

  generic subroutine publish(x, view)
    type(integer, real), intent(in), rank(0:1) :: x
    typeof(x), pointer, protected_target, intent(out), rank(rank(x)) :: view
    allocate(view, source=x)
  end subroutine

  pure generic function observe(view) result(total)
    type(integer, real), pointer, protected_target, intent(in), rank(0:1) :: view
    real :: total
    total = real(sum([view]))
  end function

  generic subroutine retarget(view, destination)
    type(integer, real), pointer, protected_target, intent(inout), rank(0:1) :: view
    typeof(view), target, intent(in), rank(rank(view)) :: destination
    view => destination
  end subroutine
end module

program audit_integration_attribute_preservation_p
  use audit_integration_attribute_preservation_m
  implicit none
  integer, asynchronous :: ivec(6), igrid(3, 2)
  real, asynchronous :: rvec(5), rgrid(2, 4)
  integer, volatile :: ivol, ivols(6)
  real, volatile :: rvol, rvols(4)
  integer, pointer, protected_target :: iview, iviews(:)
  real, pointer, protected_target :: rview, rviews(:)
  integer, target :: iholder, iholders(3)
  real, target :: rholder, rholders(2)
  integer :: unit, i
  real :: total

  open(newunit=unit, status='scratch', form='unformatted', access='sequential', &
       asynchronous='yes', action='readwrite')
  ivec = [(i, i=1, 6)]
  call async_round_trip(ivec(1:6:2), unit, total)
  if (total /= 9.0 .or. any(ivec /= [(i, i=1, 6)])) error stop "integer rank-one asynchronous"
  igrid = reshape([(10*i, i=1, 6)], [3, 2])
  call async_round_trip(igrid(1:3:2, :), unit, total)
  if (total /= 140.0 .or. any(igrid /= reshape([(10*i, i=1, 6)], [3, 2]))) then
    error stop "integer rank-two asynchronous"
  end if
  rvec = [0.5, 1.5, 2.5, 3.5, 4.5]
  call async_round_trip(rvec(5:1:-2), unit, total)
  if (total /= 7.5 .or. any(rvec /= [0.5, 1.5, 2.5, 3.5, 4.5])) error stop "real rank-one asynchronous"
  rgrid = reshape([(0.25*i, i=1, 8)], [2, 4])
  call async_round_trip(rgrid(:, 2:4:2), unit, total)
  if (total /= 0.25*(3 + 4 + 7 + 8)) error stop "real rank-two asynchronous"
  if (any(rgrid /= reshape([(0.25*i, i=1, 8)], [2, 4]))) error stop "real rank-two data"
  close(unit)

  ivol = 1
  ivols = [(i, i=1, 6)]
  rvol = 0.5
  rvols = [1.0, 2.0, 3.0, 4.0]
  call volatile_update(ivol, 4)
  call volatile_update(ivols(2:6:2), 10)
  call volatile_update(rvol, 2)
  call volatile_update(rvols(4:1:-3), -1)
  if (ivol /= 5 .or. any(ivols /= [1, 12, 3, 14, 5, 16])) error stop "integer VOLATILE specifics"
  if (rvol /= 2.5 .or. any(rvols /= [0.0, 2.0, 3.0, 3.0])) error stop "real VOLATILE specifics"

  call publish(7, iview)
  call publish([1, 2, 3], iviews)
  call publish(0.5, rview)
  call publish([1.5, 2.5], rviews)
  if (observe(iview) /= 7.0 .or. observe(iviews) /= 6.0) error stop "integer PROTECTED_TARGET"
  if (observe(rview) /= 0.5 .or. observe(rviews) /= 4.0) error stop "real PROTECTED_TARGET"
  iholder = 11
  iholders = [4, 5, 6]
  rholder = 1.25
  rholders = [2.0, 3.0]
  call retarget(iview, iholder)
  call retarget(iviews, iholders)
  call retarget(rview, rholder)
  call retarget(rviews, rholders)
  if (.not. associated(iview, iholder) .or. .not. associated(iviews, iholders)) then
    error stop "integer PROTECTED_TARGET pointer association"
  end if
  if (.not. associated(rview, rholder) .or. .not. associated(rviews, rholders)) then
    error stop "real PROTECTED_TARGET pointer association"
  end if
  if (observe(iview) /= 11.0 .or. observe(iviews) /= 15.0) error stop "integer retargeted values"
  if (observe(rview) /= 1.25 .or. observe(rviews) /= 5.0) error stop "real retargeted values"
  print '(a)', 'TEST-PASS: audit-integration-attribute-preservation'
end program
