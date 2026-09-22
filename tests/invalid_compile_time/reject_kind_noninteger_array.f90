! TEST-RULE: R708 C718
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: kind.*integer|integer.*kind expression|invalid.*kind selector
! TEST-ERROR-PHASE: compile
module reject_kind_noninteger_array_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer([1.0]) :: x
  end subroutine
end module
