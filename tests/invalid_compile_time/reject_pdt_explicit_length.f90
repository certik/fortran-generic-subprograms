! TEST-RULE: C717 C722
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C717|C722|length type parameter.*(assumed|deferred)|explicit.*length
! TEST-ERROR-PHASE: compile
module reject_pdt_explicit_length_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k=[kind(0)], n=4)) :: x
  end subroutine
end module
