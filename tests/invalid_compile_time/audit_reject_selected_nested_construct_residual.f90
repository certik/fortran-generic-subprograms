! TEST-RULE: C1155 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1155|SELECT GENERIC RANK.*rank-generic|not.*rank-generic
! TEST-ERROR-PHASE: compile
module audit_reject_selected_nested_construct_residual_m
  implicit none
contains
  generic subroutine reject_selected_nested(x, n)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: n
    select generic type (x)
    declared type is (integer)
      ! TEST-ERROR-HERE
      select generic rank (n)
      rank (0)
        n = 1
      end select
    declared type is (real)
      n = 0
    end select
  end subroutine
end module
