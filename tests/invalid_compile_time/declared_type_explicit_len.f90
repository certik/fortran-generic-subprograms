! TEST-RULE: C1160
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|(length|len) type parameters?.*assumed|DECLARED TYPE.*assumed length
! TEST-ERROR-PHASE: compile
! Invalid: C1160. A length parameter in DECLARED TYPE IS is assumed.
! Settled under either assumed-length-guards reading: whether or not a
! guard may spell an assumed length with *, an explicit length does not
! specify that the length parameter is assumed.
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
