! TEST-RULE: 15.4.3.4.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: operator.*(optional|OPTIONAL)|(optional|OPTIONAL).*(operator|operand)|nonoptional.*operator|\.[A-Za-z]+\. function.*(may not|cannot|must not) be OPTIONAL
! TEST-ERROR-PHASE: compile
! Operator dummies are nonoptional (15.4.3.4.2 p1). The generic dummy X
! cannot be optional (C802), so the ineligibility comes from the ordinary
! optional FACTOR present in every generated specific.
module integration_reject_operator_optional_dummy_m
  implicit none
  interface operator(.scaled.)
    ! TEST-ERROR-HERE
    procedure scaled
  end interface
contains
  ! TEST-ERROR-HERE
  generic function scaled(x, factor) result(y)
    type(integer, real), intent(in) :: x
    ! TEST-ERROR-HERE
    integer, intent(in), optional :: factor
    typeof(x) :: y
    y = x
    if (present(factor)) y = factor*x
  end function
end module
