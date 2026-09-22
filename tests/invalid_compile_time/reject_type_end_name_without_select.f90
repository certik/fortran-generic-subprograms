! TEST-RULE: C1163
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1163|END SELECT.*construct name|construct name.*SELECT GENERIC TYPE
! TEST-ERROR-PHASE: compile
module reject_type_end_name_without_select_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    declared type default
      continue
    ! TEST-ERROR-HERE
    end select named
  end subroutine
end module
