! TEST-RULE: 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: no matching specific|dependent.*dummy.*does not match|arguments.*same type
! TEST-ERROR-PHASE: compile
module reject_call_dependent_mismatch_m
  implicit none
contains
  generic subroutine s(x, y)
    type(integer, real), intent(in) :: x
    typeof(x), intent(in) :: y
  end subroutine
end module

program reject_call_dependent_mismatch_p
  use reject_call_dependent_mismatch_m
  implicit none
  ! TEST-ERROR-HERE
  call s(1, 1.0)
end program
