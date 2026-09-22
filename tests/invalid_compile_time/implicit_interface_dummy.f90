! TEST-RULE: C1585
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1585|dummy procedure.*explicit interface|explicit interface.*dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1585. A dummy procedure needs an explicit interface.
module implicit_interface_dummy_m
  implicit none
contains
  generic subroutine s(f, n)
    ! TEST-ERROR-HERE
    external f
    integer, intent(in) :: n
  end subroutine
end module
