! TEST-RULE: 8.5.18 14.2.2 15.4.3.4.1 15.6.2.4 15.6.2.5
! TEST-PASS: audit-integration-separate-save-state
! Each source is compiled separately. Two caller modules reach the same
! generated specifics, and their per-specific SAVE state, through the
! original generic name and through a renamed re-export that also adds an
! ordinary specific. Generated and ordinary contributions share the name.
! Only observable program behavior is checked; no object layout is assumed.
module audit_integration_separate_save_state_counter_m
  implicit none
  private
  public :: bump
  interface bump
    module procedure bump_logical
  end interface
contains
  generic function bump(x) result(count)
    type(integer, real), intent(in), rank(0:1) :: x
    integer :: count
    integer, save :: calls = 0
    calls = calls + 1
    count = calls
    if (size([x]) < 0) count = -1
  end function

  generic function bump(x) result(count)
    complex, intent(in), rank(0:0) :: x
    integer :: count
    integer, save :: calls = 0
    calls = calls + 1
    count = 500 + calls
    if (x /= x) count = -1
  end function

  function bump_logical(x) result(count)
    logical, intent(in) :: x
    integer :: count
    integer, save :: calls = 0
    calls = calls + 1
    count = 100 + calls
    if (.not. (x .or. .not. x)) count = -1
  end function
end module
