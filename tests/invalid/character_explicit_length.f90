! Invalid: C717. A length parameter in a generic type specifier is assumed
! or deferred, not an explicit length.
module character_explicit_length_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
contains
  generic subroutine s(x)
    character(len=10, kind=character_kinds) :: x
  end subroutine
end module
