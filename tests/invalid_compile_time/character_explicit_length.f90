! TEST-RULE: C717
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C717|length type parameter.*(assumed|deferred)|explicit.*length.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C717. A length parameter in a generic type specifier is assumed
! or deferred, not an explicit length.
module character_explicit_length_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    character(len=10, kind=[kind('a')]) :: x
  end subroutine
end module
