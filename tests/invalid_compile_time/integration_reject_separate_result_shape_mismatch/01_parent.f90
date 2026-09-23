! TEST-RULE: C1561 15.3.3 15.6.2.6
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|characteristics.*(interface|separate|module procedure)|(mismatch|not compatible|distinct|differ).*(interface|module procedure|declaration)|(interface|declaration).*(does not match|mismatch|differ|not compatible)|(shape|bound|extent).*(result|does not match|mismatch|differ)
! TEST-ERROR-PHASE: compile
! A singleton MODULE GENERIC interface (no generic declaration) isolates
! C1561: the automatic result bound of the definition depends on SIZE(X)
! differently from the interface body (15.3.3).
module integration_reject_separate_result_shape_mismatch_m
  implicit none
  interface
    module generic function spread(x) result(y)
      integer, intent(in) :: x(:)
      integer :: y(size(x))
    end function
  end interface
end module
