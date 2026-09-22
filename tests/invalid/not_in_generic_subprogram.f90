! Invalid: C801. A generic type declaration is allowed only in a generic
! subprogram.
module not_in_generic_subprogram_m
  implicit none
contains
  subroutine s(x)
    type(integer, real) :: x
  end subroutine
end module
