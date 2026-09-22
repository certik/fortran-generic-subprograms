! TEST-RULE: C722
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C722|kind type parameter.*asterisk|asterisk.*length parameter
! TEST-ERROR-PHASE: compile
module reject_pdt_kind_star_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k=*, n=*)) :: x
  end subroutine
end module
