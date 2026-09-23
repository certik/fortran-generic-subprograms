! TEST-RULE: 7.3.2.2 15.6.2.4
! TEST-DRAFT: empty-expansion
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: empty.*kind|kind set.*empty|no specific
! TEST-ERROR-PHASE: compile
! Selected empty-expansion reading only. The zero-sized rank-one kind array
! satisfies C718 but names no kind. Neither 7.3.2.2 nor 15.6.2.4 says whether
! that denotes zero specifics or is invalid, so this fixture records only the
! reading that requires a nonempty kind set. It is not settled conformance.
module reject_empty_kind_set_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer([integer ::]) :: x
  end subroutine
end module
