! TEST-RULE: 15.5.2.10 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: (dummy|actual) procedure.*(pure|PURE|interface|characteristic)|pure.*(dummy|actual) procedure|impure.*(pure|actual)|interface.*(mismatch|does not match|incompatible)|no (matching )?specific (function|procedure|subroutine)|matches the actual arguments
! TEST-ERROR-PHASE: compile
! The integer data argument selects the integer specific, whose callback is
! declared PURE. A pure actual could be associated with an impure dummy, but
! this impure actual cannot be associated with the pure dummy (15.5.2.10 p1).
module integration_reject_callback_purity_mismatch_m
  implicit none
contains
  generic function apply(f, x) result(y)
    type(integer, real), intent(in) :: x
    interface
      pure function f(a) result(b)
        import :: x
        typeof(x), intent(in) :: a
        typeof(x) :: b
      end function
    end interface
    typeof(x) :: y
    y = f(x)
  end function
end module

program integration_reject_callback_purity_mismatch_p
  use integration_reject_callback_purity_mismatch_m
  implicit none
  integer :: calls = 0
  ! TEST-ERROR-HERE
  if (apply(noisy_double, 2) /= 4) error stop "unreachable"
  if (calls /= 1) error stop "unreachable"
contains
  function noisy_double(a) result(b)
    integer, intent(in) :: a
    integer :: b
    calls = calls + 1
    b = 2*a
  end function
end program
