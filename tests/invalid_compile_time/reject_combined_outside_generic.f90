! TEST-RULE: C801
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C801|generic type declaration.*generic subprogram|outside.*generic
! TEST-ERROR-PHASE: compile
module reject_combined_outside_generic_m
  implicit none
contains
  subroutine s(x)
    ! TEST-ERROR-HERE
    type(integer, real), rank(0:1) :: x
  end subroutine
end module
