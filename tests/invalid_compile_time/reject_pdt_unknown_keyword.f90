! TEST-RULE: C720
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C720|unknown.*type parameter|not.*parameter.*keyword
! TEST-ERROR-PHASE: compile
module reject_pdt_unknown_keyword_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k=[kind(0)], n=*, unknown=1)) :: x
  end subroutine
end module
