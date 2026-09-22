! TEST-RULE: 7.3.2.2 15.6.2.4
! TEST-DRAFT: empty-expansion
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: empty.*kind|kind set.*empty|no specific
! TEST-ERROR-PHASE: compile
module reject_empty_kind_set_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer([integer ::]) :: x
  end subroutine
end module
