! TEST-RULE: C1161
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1161|duplicate.*(type|guard)|same type.*more than one
! TEST-ERROR-PHASE: compile
! Invalid: C1161. The same type and kind type parameters in two guards.
module pdt_guard_duplicate_m
  implicit none
  type :: u(k)
    integer, kind :: k
    integer(k) :: v
  end type
contains
  generic subroutine s(x)
    type(u(k=[kind(0)])), intent(inout) :: x
    select generic type (x)
    declared type is (u(k=kind(0)))
      x%v = 1
    ! TEST-ERROR-HERE
    declared type is (u(k=kind(0)))
      x%v = 2
    end select
  end subroutine
end module
