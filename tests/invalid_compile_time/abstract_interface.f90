! Invalid: C1564. GENERIC is not allowed in an abstract interface.
module abstract_interface_m
  implicit none
  abstract interface
    generic subroutine s(x)
      integer :: x
    end subroutine
  end interface
end module
