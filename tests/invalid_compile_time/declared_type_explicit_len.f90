! Invalid: C1160. A length parameter in DECLARED TYPE IS is assumed.
module declared_type_explicit_len_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
contains
  generic subroutine s(x)
    character(len=*, kind=character_kinds) :: x
    select generic type (x)
    declared type is (character(len=10))
      x = "abcdefghij"
    end select
  end subroutine
end module
