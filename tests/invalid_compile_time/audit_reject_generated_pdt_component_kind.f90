! TEST-RULE: C727 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C727|kind.*not supported|unsupported.*kind|invalid.*component.*kind
! TEST-ERROR-PHASE: compile
module audit_reject_generated_pdt_component_kind_m
  implicit none
  type :: dangerous(k)
    integer, kind :: k
    integer(k) :: value
  end type
contains
  generic subroutine reject_component_kind(x)
    ! The user PDT kind value -1 is permitted, but the generated
    ! INTEGER(K) component for that specialization is not.
    ! TEST-ERROR-HERE
    type(dangerous(k=[kind(0), -1])), intent(in) :: x
  end subroutine
end module
