! TEST-RULE: C1544 15.5.2.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1544|conditional.*(variable|definable)|consequent.*(variable|definable)|INTENT.*(OUT|INOUT).*(consequent|conditional)|(non-variable|not a variable).*(definition context|INTENT)
! TEST-ERROR-PHASE: compile
! Every generated specific has an INTENT(INOUT) generic dummy, so each
! consequent-arg of the conditional argument has to be a variable.
module integration_reject_conditional_expression_definable_m
  implicit none
contains
  generic subroutine accumulate(x, step)
    type(integer, real), intent(inout) :: x
    typeof(x), intent(in) :: step
    x = x + step
  end subroutine
end module

program integration_reject_conditional_expression_definable_p
  use integration_reject_conditional_expression_definable_m
  implicit none
  logical :: flag
  integer :: total
  flag = .true.
  total = 0
  ! TEST-ERROR-HERE
  call accumulate((flag ? total : 1), 5)
end program
