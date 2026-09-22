! TEST-RULE: 15.5.2.7
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: actual argument.*pointer|POINTER dummy.*pointer actual|must be.*POINTER
! TEST-ERROR-PHASE: compile
module reject_call_pointer_requirement_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), pointer, intent(inout) :: x
  end subroutine
end module

program reject_call_pointer_requirement_p
  use reject_call_pointer_requirement_m
  implicit none
  integer, target :: value
  ! TEST-ERROR-HERE
  call s(value)
end program
