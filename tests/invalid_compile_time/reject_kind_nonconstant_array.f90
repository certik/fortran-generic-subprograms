! TEST-RULE: R708 C718
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: kind.*constant|constant expression.*kind|nonconstant.*kind
! TEST-ERROR-PHASE: compile
module reject_kind_nonconstant_array_m
  implicit none
contains
  generic subroutine s(k, x)
    integer, intent(in) :: k
    ! TEST-ERROR-HERE
    integer([k]) :: x
  end subroutine
end module
