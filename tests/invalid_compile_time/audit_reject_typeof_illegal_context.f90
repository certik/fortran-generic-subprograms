! TEST-RULE: C710
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C710|TYPEOF.*(type declaration|component definition)|TYPEOF.*function statement
! TEST-ERROR-PHASE: compile
module audit_reject_typeof_illegal_context_m
  implicit none
  integer :: seed = 3
contains
  ! TEST-ERROR-HERE
  generic typeof(seed) function illegal_prefix() result(value)
    value = seed
  end function
end module
