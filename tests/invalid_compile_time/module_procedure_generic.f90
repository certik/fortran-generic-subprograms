! TEST-RULE: C1510
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1510|MODULE PROCEDURE.*generic|generic name.*MODULE PROCEDURE
! TEST-ERROR-PHASE: compile
! Invalid: C1510. MODULE PROCEDURE shall not name a generic.
module module_procedure_generic_m
  implicit none
  interface operator(.combine.)
    ! TEST-ERROR-HERE
    module procedure add
  end interface
contains
  generic function add(a, b) result(c)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a
  end function
end module
