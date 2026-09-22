! TEST-RULE: C715
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C715|CLASS.*extensible|intrinsic type.*CLASS
! TEST-ERROR-PHASE: compile
! Invalid: C715. CLASS generic specifiers must be extensible types.
module class_not_extensible_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    class(integer, real) :: x
  end subroutine
end module
