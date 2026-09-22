! TEST-RULE: C801
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C801|generic type declaration.*generic subprogram|interface body.*generic
! TEST-ERROR-PHASE: compile
module reject_generic_decl_in_interface_m
  implicit none
  interface
    subroutine s(x)
      ! TEST-ERROR-HERE
      type(integer, real) :: x
    end subroutine
  end interface
end module
