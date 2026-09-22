! TEST-RULE: C1505
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1505|generic name.*generic interface|specific.*generic name
! TEST-ERROR-PHASE: compile
! Invalid: C1505. A generic name's specific shall not itself be a generic name.
module generic_in_generic_name_m
  implicit none
  interface g
    ! TEST-ERROR-HERE
    procedure f
  end interface
contains
  generic subroutine f(x)
    type(integer, real) :: x
  end subroutine
end module
