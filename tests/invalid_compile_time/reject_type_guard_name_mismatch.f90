! TEST-RULE: C1163
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1163|type guard.*construct name|construct name.*mismatch
! TEST-ERROR-PHASE: compile
module reject_type_guard_name_mismatch_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    expected: select generic type (x)
    ! TEST-ERROR-HERE
    declared type is (integer) other
      x = 0
    end select expected
  end subroutine
end module
