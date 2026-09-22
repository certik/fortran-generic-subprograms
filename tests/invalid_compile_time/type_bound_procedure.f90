! Invalid: C798. A type-bound procedure names a specific module procedure.
! A generic subprogram has no specific name.
module type_bound_procedure_m
  implicit none
  type :: t
    integer :: n = 0
  contains
    procedure :: bump
  end type
contains
  generic subroutine bump(x)
    class(t), intent(inout) :: x
    x%n = x%n + 1
  end subroutine
end module
