! TEST-RULE: C1517 15.4.3.4.5 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|result type.*not distinguish
! TEST-ERROR-PHASE: compile
! Two same-name generic functions extend one generic name (15.6.2.4 NOTE 4).
! Each family is valid alone. The generated rank-one specifics have the same
! dummy characteristics and differ only in the result type, which never
! disambiguates a reference, so that pair violates C1517.
module reject_generic_result_only_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic function convert(x) result(y)
    integer, intent(in), rank(0:1) :: x
    integer :: y
    y = 1
  end function

  ! TEST-ERROR-HERE
  generic function convert(x) result(y)
    integer, intent(in), rank(1:2) :: x
    real :: y
    y = 2.0
  end function
end module
