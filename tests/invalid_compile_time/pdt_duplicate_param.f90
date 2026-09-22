! TEST-RULE: C721
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C721|type parameter.*more than once|duplicate.*parameter
! TEST-ERROR-PHASE: compile
! Invalid: C721. Each type parameter appears at most once.
module pdt_duplicate_param_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k=[kind(0)], k=[kind(0)], n=*)) :: x
  end subroutine
end module
