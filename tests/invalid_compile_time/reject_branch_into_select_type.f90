! TEST-RULE: 11.1.11.2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: branch.*(SELECT GENERIC|construct)|target.*outside.*construct
! TEST-ERROR-PHASE: compile
module reject_branch_into_select_type_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    ! TEST-ERROR-HERE
    go to 100
    named: select generic type (x)
    declared type default
      continue
    100 end select named
  end subroutine
end module
