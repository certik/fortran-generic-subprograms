! TEST-RULE: C1583
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1583|internal subprogram.*generic|nested.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C1583. An internal subprogram of a generic subprogram shall not
! be generic.
module nested_generic_m
  implicit none
contains
  generic subroutine outer(x)
    integer, rank(0:1) :: x
  contains
    ! TEST-ERROR-HERE
    generic subroutine inner(y)
      integer :: y
    end subroutine
  end subroutine
end module
