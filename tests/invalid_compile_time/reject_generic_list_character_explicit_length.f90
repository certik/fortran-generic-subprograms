! TEST-RULE: C717
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C717|length type parameter.*(assumed|deferred)|explicit.*character length
! TEST-ERROR-PHASE: compile
module reject_generic_list_character_explicit_length_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(character(len=4), integer) :: x
  end subroutine
end module
