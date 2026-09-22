! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|character length.*not distinguish
! TEST-ERROR-PHASE: compile
module reject_generic_length_only_m
  implicit none
  ! TEST-ERROR-HERE
  interface consume
    module procedure consume_one
    ! TEST-ERROR-HERE
    module procedure consume_two
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine consume_one(x)
    character(len=1), intent(in) :: x
  end subroutine

  ! TEST-ERROR-HERE
  subroutine consume_two(x)
    character(len=2), intent(in) :: x
  end subroutine
end module
