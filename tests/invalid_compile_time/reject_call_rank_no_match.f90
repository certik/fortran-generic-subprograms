! TEST-RULE: 15.5.5.2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: no matching specific|rank.*does not match|generic.*rank
! TEST-ERROR-PHASE: compile
module reject_call_rank_no_match_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(1:2), intent(in) :: x
  end subroutine
end module

program reject_call_rank_no_match_p
  use reject_call_rank_no_match_m
  implicit none
  ! TEST-ERROR-HERE
  call s(1)
end program
