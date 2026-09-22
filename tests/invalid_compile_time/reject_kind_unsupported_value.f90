! TEST-RULE: 4.2(4) 7.4
! TEST-REQUIRES: integer_kinds>=1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: kind.*not supported|unsupported.*kind|invalid.*kind.*-1
! TEST-ERROR-PHASE: compile
module reject_kind_unsupported_value_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer([kind(0), -1]) :: x
  end subroutine
end module
