! TEST-RULE: C1160
! TEST-DRAFT: assumed-length-guards
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|length type parameter.*assumed|missing.*assumed length
! TEST-ERROR-PHASE: compile
module reject_guard_character_missing_length_m
  implicit none
contains
  generic subroutine s(x)
    character(len=*, kind=[kind('a')]) :: x
    select generic type (x)
    ! TEST-ERROR-HERE
    declared type is (character(kind=kind('a')))
      continue
    end select
  end subroutine
end module
