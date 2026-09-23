! TEST-RULE: C1542 15.5.2.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1542|conditional.*(same|different|mismatch).*rank|consequent.*rank|rank.*consequent
! TEST-ERROR-PHASE: compile
! A scalar and a rank-one consequent would select different rank-generic
! specifics; C1542 requires one rank for every consequent.
module integration_reject_conditional_rank_mismatch_m
  implicit none
contains
  generic function describe(x) result(code)
    type(integer, real), intent(in), rank(0:1) :: x
    integer :: code
    code = rank(x)
  end function
end module

program integration_reject_conditional_rank_mismatch_p
  use integration_reject_conditional_rank_mismatch_m
  implicit none
  logical :: flag
  integer :: scalar, vector(2)
  flag = .true.
  scalar = 1
  vector = [2, 3]
  ! TEST-ERROR-HERE
  if (describe((flag ? scalar : vector)) /= 0) error stop "unreachable"
end program
