! TEST-RULE: 4.2(3) R816 R817 R1029 C1011 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: array bound.*integer|specification expression.*integer|scalar integer.*bound|REAL.*bound
! TEST-ERROR-PHASE: compile
module audit_reject_selected_specification_residual_m
  implicit none
contains
  generic subroutine reject_selected_specification(x, n)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: n
    select generic type (x)
    declared type is (integer)
      block
        ! TEST-ERROR-HERE
        integer :: invalid_bound(real(x))
        n = size(invalid_bound)
      end block
    declared type is (real)
      n = 0
    end select
  end subroutine
end module
