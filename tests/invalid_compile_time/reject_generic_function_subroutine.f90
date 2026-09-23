! TEST-RULE: C1517 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|generic interface.*(SUBROUTINE|FUNCTION)|procedures.*(all|either).*(SUBROUTINE|FUNCTION)|both.*function.*subroutine|(function|subroutine).*same generic
! TEST-ERROR-PHASE: compile
! Two same-name generic subprograms extend one generic name (15.6.2.4 NOTE 4):
! one generates INTEGER function specifics and the other REAL subroutine
! specifics. Every pair is TKR distinguishable, so the only violation is the
! C1517 requirement that all procedures of a generic name be functions or all
! be subroutines.
module reject_generic_function_subroutine_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic function mixed(x) result(y)
    integer, intent(in), rank(0:1) :: x
    integer :: y
    y = 1
  end function

  ! TEST-ERROR-HERE
  generic subroutine mixed(x)
    real, intent(in), rank(0:1) :: x
  end subroutine
end module
