! TEST-RULE: C1159
! TEST-DRAFT: character-ordinary-parse
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|not.*type-generic|selector.*type-generic dummy
! TEST-ERROR-PHASE: compile
! Rejection is expected only under the character-ordinary-parse policy, where
! CHARACTER(LEN=*) is ordinary assumed-length character and is not type-generic.
module select_on_assumed_character_m
  implicit none
contains
  generic subroutine s(x)
    character(len=*) :: x
    ! TEST-ERROR-HERE
    select generic type (x)
    declared type default
      continue
    end select
  end subroutine
end module
