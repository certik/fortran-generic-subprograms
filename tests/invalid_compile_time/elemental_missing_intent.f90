! TEST-RULE: C15137
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15137|elemental.*dummy.*INTENT|INTENT.*elemental
! TEST-ERROR-PHASE: compile
! Invalid: C15137. An elemental dummy without VALUE needs an intent.
module elemental_missing_intent_m
  implicit none
contains
  elemental generic function f(x) result(y)
    ! TEST-ERROR-HERE
    integer :: x
    integer :: y
    y = x
  end function
end module
