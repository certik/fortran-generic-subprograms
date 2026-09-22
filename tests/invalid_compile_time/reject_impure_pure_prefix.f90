! TEST-RULE: C1556
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1556|IMPURE.*PURE|PURE.*IMPURE|incompatible.*prefix
! TEST-ERROR-PHASE: compile
module reject_impure_pure_prefix_m
  implicit none
contains
  ! TEST-ERROR-HERE
  impure pure generic subroutine s(x)
    integer, intent(in) :: x
  end subroutine
end module
