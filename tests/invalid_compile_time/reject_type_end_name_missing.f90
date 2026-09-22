! TEST-RULE: C1163
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1163|END SELECT.*construct name|missing.*construct name
! TEST-ERROR-PHASE: compile
module reject_type_end_name_missing_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    named: select generic type (x)
    declared type default
      continue
    ! TEST-ERROR-HERE
    end select
  end subroutine
end module
