! TEST-RULE: C802
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|generic.*declaration.*dummy|function result.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C802. The function result is not a dummy data object, so it cannot
! be declared with a generic-type-spec.
module generic_result_m
  implicit none
contains
  generic function f(x) result(y)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    type(integer, real) :: y
    y = x
  end function
end module
