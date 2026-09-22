! TEST-RULE: C1511
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1511|procedure.*specified previously|already specified.*generic|already present.*interface
! TEST-ERROR-PHASE: compile
module reject_duplicate_procedure_insertion_m
  implicit none
  interface consume
    module procedure consume_integer
    ! TEST-ERROR-HERE
    module procedure consume_integer
  end interface
contains
  subroutine consume_integer(x)
    integer, intent(in) :: x
  end subroutine
end module
