! TEST-RULE: 4.2(6) 8.8p4 15.6.2.4p2 20.1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: no implicit type|undeclared.*missing_value|missing_value.*not declared
! TEST-ERROR-PHASE: compile
module audit_reject_selected_name_use_residual_m
  implicit none
contains
  generic subroutine reject_selected_name(x, n)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: n
    select generic type (x)
    declared type is (integer)
      ! TEST-ERROR-HERE
      n = missing_value
    declared type is (real)
      n = 0
    end select
  end subroutine
end module
