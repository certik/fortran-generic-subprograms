! Invalid: C802. A generic dummy shall not have the OPTIONAL attribute.
module optional_dummy_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), optional :: x
  end subroutine
end module
