! TEST-RULE: C719
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C719|type.*not accessible|private.*derived type
! TEST-ERROR-PHASE: compile
module reject_pdt_inaccessible_definition_m
  implicit none
  private
  type :: hidden_t(k)
    integer, kind :: k
    integer(k) :: value
  end type
end module

module reject_pdt_inaccessible_m
  use reject_pdt_inaccessible_definition_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(hidden_t(k=[kind(0)])) :: x
  end subroutine
end module
