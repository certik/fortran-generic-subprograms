! TEST-RULE: C1163
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1163|END SELECT.*construct name|construct name.*mismatch
! TEST-ERROR-PHASE: compile
module reject_type_end_name_mismatch_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    expected: select generic type (x)
    declared type default
      continue
    ! TEST-ERROR-HERE
    end select other
  end subroutine
end module
