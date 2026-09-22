! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|keyword.*not distinguish
! TEST-ERROR-PHASE: compile
module reject_generic_keyword_ambiguity_m
  implicit none
  ! TEST-ERROR-HERE
  interface consume
    module procedure integer_then_real
    ! TEST-ERROR-HERE
    module procedure real_then_integer
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine integer_then_real(i, r)
    integer, intent(in) :: i
    real, intent(in) :: r
  end subroutine

  ! TEST-ERROR-HERE
  subroutine real_then_integer(r, i)
    real, intent(in) :: r
    integer, intent(in) :: i
  end subroutine
end module
