! TEST-RULE: C802 C1585
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C802|C1585|dummy data object|dummy procedure.*explicit interface|interface.*specified explicitly
! TEST-ERROR-PHASE: compile
! This is intentionally a combined C802/C1585 case. The ordinary counterpart
! INTEGER :: p; EXTERNAL :: p is a valid implicitly interfaced dummy function.
! Replacing INTEGER with a duplicate INTEGER generic type list simultaneously
! makes the declaration require a dummy data object and leaves the dummy
! procedure without the explicit interface required in a generic subprogram.
module reject_generic_dummy_procedure_m
  implicit none
contains
  generic subroutine s(p)
    ! TEST-ERROR-HERE
    external :: p
    ! TEST-ERROR-HERE
    type(integer, integer) :: p
  end subroutine
end module
