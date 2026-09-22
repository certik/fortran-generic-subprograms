! TEST-RULE: C1161
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1161|duplicate.*(type|guard)|same type.*kind
! TEST-ERROR-PHASE: compile
module reject_duplicate_guard_equivalent_kind_m
  implicit none
contains
  generic subroutine s(x)
    integer([kind(0)]) :: x
    select generic type (x)
    declared type is (integer)
      continue
    ! TEST-ERROR-HERE
    declared type is (integer(kind(0)))
      continue
    end select
  end subroutine
end module
