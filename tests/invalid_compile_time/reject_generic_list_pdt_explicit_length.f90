! TEST-RULE: C717
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C717|length type parameter.*(assumed|deferred)|explicit.*length
! TEST-ERROR-PHASE: compile
module reject_generic_list_pdt_explicit_length_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k=kind(0), n=4), integer) :: x
  end subroutine
end module
