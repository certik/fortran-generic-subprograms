! Invalid: C804. A *char-length on a generic declaration is * or :, not an
! explicit length.
module char_length_explicit_override_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
contains
  generic subroutine s(x)
    character(len=*, kind=character_kinds) :: x*10
  end subroutine
end module
