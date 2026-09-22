! TEST-RULE: C1161
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1161|duplicate.*(type|guard)|same type.*more than one
! TEST-ERROR-PHASE: compile
! Invalid: C1161. The same type and kind appear in two guards.
module duplicate_type_guard_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    declared type is (integer)
      x = 1
    ! TEST-ERROR-HERE
    declared type is (integer)
      x = 2
    end select
  end subroutine
end module
