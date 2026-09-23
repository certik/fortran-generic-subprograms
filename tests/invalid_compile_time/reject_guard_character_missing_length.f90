! TEST-RULE: C1160
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|(length|len) type parameters?.*assumed|missing.*assumed length
! TEST-ERROR-PHASE: compile
! Invalid: C1160. The character guard omits its length parameter, so it takes
! a nonassumed length. Settled under either assumed-length-guards reading:
! whether or not a guard may spell an assumed length with *, an omitted
! length does not specify that the length parameter is assumed.
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
