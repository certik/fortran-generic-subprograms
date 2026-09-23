! TEST-RULE: 15.5.2.10 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: (dummy|actual) procedure.*(interface|characteristic|kind)|interface.*(mismatch|does not match|incompatible)|characteristics.*(differ|mismatch)|no (matching )?specific (function|procedure|subroutine)|matches the actual arguments
! TEST-ERROR-PHASE: compile
! The data argument selects the double-precision specific. Its explicit
! callback interface then requires double-precision characteristics, so the
! single-precision actual procedure violates 15.5.2.10 p1.
module integration_reject_callback_kind_mismatch_m
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  implicit none
contains
  generic function apply(f, x) result(y)
    real([single_precision, double_precision]), intent(in) :: x
    interface
      function f(a) result(b)
        import :: x
        typeof(x), intent(in) :: a
        typeof(x) :: b
      end function
    end interface
    typeof(x) :: y
    y = f(x)
  end function
end module

program integration_reject_callback_kind_mismatch_p
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  use integration_reject_callback_kind_mismatch_m
  implicit none
  real(double_precision) :: value
  value = 2.0_double_precision
  ! TEST-ERROR-HERE
  value = apply(halve_single, value)
contains
  function halve_single(a) result(b)
    real(single_precision), intent(in) :: a
    real(single_precision) :: b
    b = a/2
  end function
end program
