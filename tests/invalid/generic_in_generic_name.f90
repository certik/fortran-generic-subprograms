! Invalid: C1505. A generic name's specific shall not itself be a generic name.
module generic_in_generic_name_m
  implicit none
  interface g
    procedure f
  end interface
contains
  generic subroutine f(x)
    type(integer, real) :: x
  end subroutine
end module
