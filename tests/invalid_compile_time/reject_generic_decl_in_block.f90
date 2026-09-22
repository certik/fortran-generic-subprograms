! TEST-RULE: C801
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C801|generic type declaration.*specification part|BLOCK.*generic
! TEST-ERROR-PHASE: compile
module reject_generic_decl_in_block_m
  implicit none
contains
  generic subroutine s(x)
    integer, intent(in) :: x
    block
      ! TEST-ERROR-HERE
      type(integer, real) :: local
    end block
  end subroutine
end module
