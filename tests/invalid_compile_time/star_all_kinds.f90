! TEST-RULE: R708
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: REAL.*asterisk|generic kind.*array|invalid.*kind selector
! TEST-ERROR-PHASE: compile
! Invalid syntax. Kind sets are rank-one arrays. REAL(*) was rejected
! (25-156r1 alternative 1b) and is not a generic-intrinsic-type-spec.
module star_all_kinds_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    real(*) :: x
  end subroutine
end module
