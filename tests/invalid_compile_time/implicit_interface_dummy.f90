! Invalid: C1585. A dummy procedure needs an explicit interface.
module implicit_interface_dummy_m
  implicit none
contains
  generic subroutine s(f, n)
    external f
    integer, intent(in) :: n
  end subroutine
end module
