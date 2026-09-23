! TEST-RULE: C1561 15.3.3 15.6.2.6
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|characteristics.*(interface|separate|module procedure)|(mismatch|not compatible|distinct|differ).*(interface|module procedure|declaration)|(interface|declaration).*(does not match|mismatch|differ|not compatible)|(ALLOCATABLE|allocatable|POINTER|pointer).*(result|does not match|mismatch|differ)
! TEST-ERROR-PHASE: compile
! A singleton MODULE GENERIC interface isolates C1561: whether the result is
! allocatable or a pointer is a result characteristic (15.3.3).
module integration_reject_separate_result_attribute_mismatch_m
  implicit none
  interface
    module generic function copy(x) result(y)
      integer, intent(in) :: x(:)
      integer, allocatable :: y(:)
    end function
  end interface
end module
