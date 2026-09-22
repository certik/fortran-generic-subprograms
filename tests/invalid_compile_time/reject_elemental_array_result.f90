! TEST-RULE: C15136
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15136|elemental.*result.*scalar|array result.*elemental
! TEST-ERROR-PHASE: compile
module reject_elemental_array_result_m
  implicit none
contains
  elemental generic function f(x) result(y)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    integer :: y(1)
    y = x
  end function
end module
