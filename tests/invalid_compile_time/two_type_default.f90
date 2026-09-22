! TEST-RULE: C1162
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1162|more than one.*TYPE DEFAULT|duplicate.*TYPE DEFAULT
! TEST-ERROR-PHASE: compile
! Invalid: C1162. At most one DECLARED TYPE DEFAULT.
! The constraint text says "TYPE DEFAULT"; the syntax is DECLARED TYPE DEFAULT.
module two_type_default_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    declared type default
      x = 1
    ! TEST-ERROR-HERE
    declared type default
      x = 2
    end select
  end subroutine
end module
