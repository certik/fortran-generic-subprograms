! TEST-RULE: R1157
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: TYPE DEFAULT|expected.*DECLARED TYPE|invalid.*type guard
! TEST-ERROR-PHASE: compile
! Invalid syntax. The guard is DECLARED TYPE DEFAULT (R1157). C1162's prose
! says "TYPE DEFAULT"; that spelling is not the syntax.
module type_default_syntax_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    ! TEST-ERROR-HERE
    type default
      x = 1
    end select
  end subroutine
end module
