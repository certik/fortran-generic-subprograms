! TEST-RULE: C1514
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1514|ambiguous.*operator|operator.*not distinguishable
! TEST-ERROR-PHASE: compile
module reject_operator_ambiguous_m
  implicit none
  ! TEST-ERROR-HERE
  interface operator(.combine.)
    module procedure combine_integer
    ! TEST-ERROR-HERE
    module procedure combine_real_result
  end interface
contains
  ! TEST-ERROR-HERE
  integer function combine_integer(x)
    integer, intent(in) :: x
    combine_integer = x
  end function

  ! TEST-ERROR-HERE
  real function combine_real_result(x)
    integer, intent(in) :: x
    combine_real_result = real(x)
  end function
end module
