! TEST-RULE: C1564
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1564|GENERIC.*(abstract interface|MODULE)|abstract interface.*GENERIC
! TEST-ERROR-PHASE: compile
! Invalid: C1564. GENERIC is not allowed in an abstract interface.
module abstract_interface_m
  implicit none
  abstract interface
    ! TEST-ERROR-HERE
    generic subroutine s(x)
      integer :: x
    end subroutine
  end interface
end module
