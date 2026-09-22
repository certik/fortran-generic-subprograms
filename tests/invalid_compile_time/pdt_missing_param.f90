! TEST-RULE: C721
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C721|required.*type parameter|missing.*kind parameter
! TEST-ERROR-PHASE: compile
! Invalid: C721. A kind parameter with no default has to appear in the spec.
module pdt_missing_param_m
  implicit none
  type :: t(k1, k2, n)
    integer, kind :: k1, k2
    integer, len :: n
    integer(k1) :: v(n)
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k1=[kind(0)], n=*)) :: x
  end subroutine
end module
