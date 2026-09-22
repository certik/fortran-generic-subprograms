! TEST-RULE: C1561
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|result.*does not match|different.*result.*interface
! TEST-ERROR-PHASE: compile
module reject_separate_result_mismatch_m
  implicit none
  interface
    module generic function f(x) result(y)
      integer, intent(in) :: x
      integer :: y
    end function
  end interface
end module
