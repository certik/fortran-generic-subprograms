! TEST-RULE: C15136
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15136|elemental.*result.*POINTER|POINTER.*elemental.*result
! TEST-ERROR-PHASE: compile
module reject_elemental_pointer_result_m
  implicit none
contains
  elemental generic function f(x) result(y)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    integer, pointer :: y
    nullify(y)
  end function
end module
