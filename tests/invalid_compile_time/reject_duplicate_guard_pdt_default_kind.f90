! TEST-RULE: C1161
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1161|duplicate.*(type|guard)|default.*kind.*same
! TEST-ERROR-PHASE: compile
module reject_duplicate_guard_pdt_default_kind_m
  implicit none
  type :: t(k)
    integer, kind :: k = kind(0)
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    type(t(k=[kind(0)])) :: x
    select generic type (x)
    declared type is (t)
      continue
    ! TEST-ERROR-HERE
    declared type is (t(k=kind(0)))
      continue
    end select
  end subroutine
end module
