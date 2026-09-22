! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|generic interface.*(SUBROUTINE|FUNCTION)|procedures.*(all|either).*(SUBROUTINE|FUNCTION)
! TEST-ERROR-PHASE: compile
module reject_generic_function_subroutine_m
  implicit none
  ! TEST-ERROR-HERE
  interface mixed
    module procedure as_function
    ! TEST-ERROR-HERE
    module procedure as_subroutine
  end interface
contains
  ! TEST-ERROR-HERE
  integer function as_function(x)
    integer, intent(in) :: x
    as_function = x
  end function

  ! TEST-ERROR-HERE
  subroutine as_subroutine(x)
    integer, intent(in) :: x
  end subroutine
end module
