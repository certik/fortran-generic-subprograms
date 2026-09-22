! TEST-RULE: 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: IAND.*integer|arguments.*IAND|invalid.*real.*IAND
! TEST-ERROR-PHASE: compile
module reject_unused_specific_invalid_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), intent(inout) :: x
    ! TEST-ERROR-HERE
    x = iand(x, 1)
  end subroutine
end module

program reject_unused_specific_invalid_p
  use reject_unused_specific_invalid_m
  implicit none
  integer :: value
  call s(value)
end program
