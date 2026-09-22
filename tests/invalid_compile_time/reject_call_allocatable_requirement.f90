! TEST-RULE: 15.5.2.6
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: actual argument.*allocatable|ALLOCATABLE dummy.*allocatable actual|must be.*ALLOCATABLE
! TEST-ERROR-PHASE: compile
module reject_call_allocatable_requirement_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), allocatable, intent(inout) :: x
  end subroutine
end module

program reject_call_allocatable_requirement_p
  use reject_call_allocatable_requirement_m
  implicit none
  integer :: value
  ! TEST-ERROR-HERE
  call s(value)
end program
