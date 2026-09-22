! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|optional.*not distinguish
! TEST-ERROR-PHASE: compile
module reject_generic_optional_ambiguity_m
  implicit none
  ! TEST-ERROR-HERE
  interface consume
    module procedure consume_one
    ! TEST-ERROR-HERE
    module procedure consume_optional
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine consume_one(x)
    integer, intent(in) :: x
  end subroutine

  ! TEST-ERROR-HERE
  subroutine consume_optional(x, y)
    integer, intent(in) :: x
    real, intent(in), optional :: y
  end subroutine
end module
