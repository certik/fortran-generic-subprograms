! TEST-RULE: C1160
! TEST-DRAFT: assumed-length-guards
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|length type parameter.*assumed|DECLARED TYPE.*assumed length
! TEST-ERROR-PHASE: compile
! Invalid: C1160. A length parameter in DECLARED TYPE IS is assumed.
module declared_type_explicit_len_m
  implicit none
contains
  generic subroutine s(x)
    character(len=*, kind=[kind('a')]) :: x
    select generic type (x)
    ! TEST-ERROR-HERE
    declared type is (character(len=10))
      x = "abcdefghij"
    end select
  end subroutine
end module
