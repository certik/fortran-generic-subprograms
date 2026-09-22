! TEST-RULE: C719 C722
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C719|parameterized type.*kind parameter|array.*length parameter
! TEST-ERROR-PHASE: compile
module reject_pdt_without_kind_parameter_m
  implicit none
  type :: length_only_t(n)
    integer, len :: n
    integer :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(length_only_t(n=[1])) :: x
  end subroutine
end module
