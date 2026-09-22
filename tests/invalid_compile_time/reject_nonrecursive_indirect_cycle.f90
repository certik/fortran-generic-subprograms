! TEST-RULE: 15.6.2.1p3
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: NON_RECURSIVE.*(indirect|recursive|cycle)|recursive.*NON_RECURSIVE
! TEST-ERROR-PHASE: compile
module reject_nonrecursive_indirect_cycle_m
  implicit none
contains
  non_recursive generic integer function f(x) result(y)
    type(integer, real), intent(in) :: x
    y = helper(1)
  contains
    integer function helper(n)
      integer, intent(in) :: n
      ! TEST-ERROR-HERE
      helper = f(n)
    end function
  end function
end module
