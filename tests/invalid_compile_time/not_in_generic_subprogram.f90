! TEST-RULE: C801
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C801|generic type declaration.*generic subprogram|outside.*generic subprogram
! TEST-ERROR-PHASE: compile
! Invalid: C801. A generic type declaration is allowed only in a generic
! subprogram.
module not_in_generic_subprogram_m
  implicit none
contains
  subroutine s(x)
    ! TEST-ERROR-HERE
    type(integer, real) :: x
  end subroutine
end module
