! TEST-RULE: C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|TYPEOF.*not.*type-generic|selector.*type-generic dummy
! TEST-ERROR-PHASE: compile
module reject_select_type_typeof_m
  implicit none
contains
  generic subroutine s(x, y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    ! TEST-ERROR-HERE
    select generic type (y)
    declared type is (integer)
      y = x
    end select
  end subroutine
end module
