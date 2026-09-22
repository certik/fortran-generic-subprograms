! TEST-RULE: C804
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C804|character length.*(asterisk|colon)|explicit.*length.*generic
! TEST-ERROR-PHASE: compile
module reject_rank_generic_entity_length_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    character(len=*), rank(0:1) :: x*10
  end subroutine
end module
