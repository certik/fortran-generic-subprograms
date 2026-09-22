! TEST-RULE: C15136
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15136|elemental.*result.*ALLOCATABLE|ALLOCATABLE.*elemental.*result
! TEST-ERROR-PHASE: compile
! Invalid: C15136. The result of an elemental function is not allocatable.
module elemental_allocatable_result_m
  implicit none
contains
  elemental generic function f(x) result(y)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    integer, allocatable :: y
    y = x
  end function
end module
