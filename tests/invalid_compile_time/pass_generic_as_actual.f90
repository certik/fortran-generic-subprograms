! TEST-RULE: C1537 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1537|actual procedure.*specific|generic name.*actual argument
! TEST-ERROR-PHASE: compile
! Invalid. A generic subprogram with no generic dummy still has a generic
! name, not a specific name (15.6.2.4 NOTE 7), so it is not an actual argument.
module pass_generic_as_actual_m
  implicit none
contains
  generic function square(x)
    real, intent(in) :: x
    real :: square
    square = x**2
  end function
end module

program pass_generic_as_actual_p
  use pass_generic_as_actual_m
  implicit none
  ! TEST-ERROR-HERE
  call take(square)
contains
  subroutine take(f)
    interface
      real function f(x)
        real, intent(in) :: x
      end function
    end interface
  end subroutine
end program
