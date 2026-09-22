! TEST-RULE: R708
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: generic intrinsic kind.*array|kind.*rank.one|unexpected.*comma
! TEST-ERROR-PHASE: compile
! Invalid syntax. The kind set is one rank-one expression, written with an
! array constructor, not as two comma-separated selector arguments.
module kind_list_not_array_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer(kind(0), kind(0)) :: x
  end subroutine
end module
