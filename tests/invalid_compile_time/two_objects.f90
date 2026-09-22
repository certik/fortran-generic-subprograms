! Invalid: C802. A generic type declaration names exactly one dummy.
module two_objects_m
  implicit none
contains
  generic subroutine s(x, y)
    type(integer, real), intent(in) :: x, y
  end subroutine
end module
