! TEST-RULE: C1561 C718 15.3.3 15.6.2.6
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|characteristics.*(interface|separate|module procedure)|(mismatch|not compatible|distinct|differ).*(interface|module procedure|declaration)|(interface|declaration).*(does not match|mismatch|differ|not compatible)|length.*(result|does not match|mismatch|differ)|character.*result.*(differ|mismatch)
! TEST-ERROR-PHASE: compile
! A singleton MODULE GENERIC interface isolates C1561: the result length
! depends on LEN(X) differently in the definition. KIND=KIND('') keeps the
! assumed-length dummy an ordinary declaration under either character
! parse reading (C718), so no generic declaration occurs in the body.
module integration_reject_separate_result_length_mismatch_m
  implicit none
  interface
    module generic function framed(x) result(y)
      character(len=*, kind=kind('')), intent(in) :: x
      character(len=len(x) + 2, kind=kind('')) :: y
    end function
  end interface
end module
