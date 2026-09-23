! TEST-RULE: C15138 15.6.2.4 15.9.1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15138|elemental.*result.*(length|type parameter|dummy argument)|specification (expression|inquiry).*elemental|LEN_TRIM.*(elemental|inquiry)
! TEST-ERROR-PHASE: compile
! LEN(label) would be a permitted specification inquiry (see
! valid/audit_integration_elemental_result_params.f90). LEN_TRIM(label) is
! not an inquiry: the result length depends on the dummy's value, so both
! generated elemental specifics violate C15138.
module integration_reject_elemental_character_result_length_m
  implicit none
contains
  elemental generic function trimmed(label, marker) result(y)
    character(len=*), intent(in) :: label
    type(integer, real), intent(in) :: marker
    ! TEST-ERROR-HERE
    character(len=len_trim(label)) :: y
    y = label
    if (marker < 0) y = ''
  end function
end module
