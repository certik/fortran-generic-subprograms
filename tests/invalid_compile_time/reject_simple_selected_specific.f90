! TEST-RULE: C15132 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15132|host associated.*simple|simple.*host.*variable
! TEST-ERROR-PHASE: compile
module reject_simple_selected_specific_m
  implicit none
  integer :: saved_value = 1
contains
  simple generic function f(x) result(y)
    type(integer, real), intent(in) :: x
    integer :: y
    select generic type (x)
    declared type is (integer)
      ! TEST-ERROR-HERE
      y = saved_value
    declared type is (real)
      y = 0
    end select
  end function
end module
