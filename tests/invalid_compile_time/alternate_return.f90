! TEST-RULE: C1584
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1584|generic.*(asterisk|alternate return)|alternate return.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C1584. A generic subprogram shall not have an asterisk dummy.
module alternate_return_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine s(*)
  end subroutine
end module
