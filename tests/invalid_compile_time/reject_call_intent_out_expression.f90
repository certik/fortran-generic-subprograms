! TEST-RULE: 15.5.2.13
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: INTENT.OUT.*definable|actual argument.*variable|non-variable.*INTENT
! TEST-ERROR-PHASE: compile
module reject_call_intent_out_expression_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), intent(out) :: x
  end subroutine
end module

program reject_call_intent_out_expression_p
  use reject_call_intent_out_expression_m
  implicit none
  ! TEST-ERROR-HERE
  call s(1)
end program
