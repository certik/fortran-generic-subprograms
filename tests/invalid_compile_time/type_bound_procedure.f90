! TEST-RULE: C798
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C798|type-bound procedure.*specific|generic name.*binding
! TEST-ERROR-PHASE: compile
! Invalid: C798. A type-bound procedure names a specific module procedure.
! A generic subprogram has no specific name.
module type_bound_procedure_m
  implicit none
  type :: t
    integer :: n = 0
  contains
    ! TEST-ERROR-HERE
    procedure :: bump
  end type
contains
  generic subroutine bump(x)
    class(t), intent(inout) :: x
    x%n = x%n + 1
  end subroutine
end module
