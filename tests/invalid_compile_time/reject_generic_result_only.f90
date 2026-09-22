! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|result type.*not distinguish
! TEST-ERROR-PHASE: compile
module reject_generic_result_only_m
  implicit none
  ! TEST-ERROR-HERE
  interface value
    module procedure integer_result
    ! TEST-ERROR-HERE
    module procedure real_result
  end interface
contains
  ! TEST-ERROR-HERE
  integer function integer_result(x)
    integer, intent(in) :: x
    integer_result = x
  end function

  ! TEST-ERROR-HERE
  real function real_result(x)
    integer, intent(in) :: x
    real_result = real(x)
  end function
end module
