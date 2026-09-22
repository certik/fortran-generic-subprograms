! Invalid: C802. A generic type declaration declares a dummy, not a local.
module generic_local_m
  implicit none
contains
  generic subroutine s(x)
    integer :: x
    type(integer, real) :: y
  end subroutine
end module
