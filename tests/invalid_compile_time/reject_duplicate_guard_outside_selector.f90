! TEST-RULE: C1161
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1161|duplicate.*(type|guard)|same type.*more than one
! TEST-ERROR-PHASE: compile
module reject_duplicate_guard_outside_selector_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    declared type is (complex)
      continue
    ! TEST-ERROR-HERE
    declared type is (complex)
      continue
    end select
  end subroutine
end module
