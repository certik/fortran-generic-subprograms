! TEST-RULE: C1513
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1513|procedure.*specified previously|duplicate.*generic
! TEST-ERROR-PHASE: compile
module reject_duplicate_generic_insertion_m
  implicit none
  interface consume
    module procedure consume_integer
  end interface
  ! TEST-ERROR-HERE
  generic :: consume => consume_integer
contains
  subroutine consume_integer(x)
    integer, intent(in) :: x
  end subroutine
end module
