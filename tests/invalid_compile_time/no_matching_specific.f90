! TEST-RULE: 15.5.5.2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: no matching specific|no specific procedure|generic.*not match
! TEST-ERROR-PHASE: compile
! Invalid. The actual is logical. Neither specific of s accepts it.
module no_matching_specific_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
  end subroutine
end module

program no_matching_specific_p
  use no_matching_specific_m
  implicit none
  ! TEST-ERROR-HERE
  call s(.true.)
end program
