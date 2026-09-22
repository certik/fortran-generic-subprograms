! TEST-RULE: C719
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C719|not.*parameterized derived type|type.*has no type parameters
! TEST-ERROR-PHASE: compile
module reject_pdt_nonparameterized_m
  implicit none
  type :: plain_t
    integer :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(plain_t([kind(0)])) :: x
  end subroutine
end module
