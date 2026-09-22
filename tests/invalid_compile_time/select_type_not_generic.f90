! TEST-RULE: C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|not.*type-generic|selector.*type-generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1159. A plain INTEGER dummy is not type-generic.
module select_type_not_generic_m
  implicit none
contains
  generic subroutine s(x)
    integer :: x
    ! TEST-ERROR-HERE
    select generic type (x)
    declared type is (integer)
      x = 1
    end select
  end subroutine
end module
