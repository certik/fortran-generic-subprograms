! TEST-RULE: C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|selector.*dummy argument|expression.*SELECT GENERIC TYPE
! TEST-ERROR-PHASE: compile
module reject_select_type_expression_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), intent(in) :: x
    ! TEST-ERROR-HERE
    select generic type (x + x)
    declared type is (integer)
      continue
    end select
  end subroutine
end module
