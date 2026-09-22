! TEST-RULE: C803
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C803|character length.*noncharacter|char-length.*CHARACTER
! TEST-ERROR-PHASE: compile
! Invalid: C803. *char-length is allowed only when every type in the
! generic-type-spec is character.
module char_length_on_noncharacter_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(character(len=*), integer) :: x*(*)
  end subroutine
end module
