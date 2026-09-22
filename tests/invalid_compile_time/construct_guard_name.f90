! TEST-RULE: C1163
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1163|guard.*construct name|construct name.*SELECT GENERIC TYPE
! TEST-ERROR-PHASE: compile
! Invalid: C1163. A type guard names the construct and SELECT does not.
module construct_guard_name_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    ! TEST-ERROR-HERE
    declared type is (integer) gr
      x = 1
    end select
  end subroutine
end module
