! Invalid: C715. Enumeration types are not extensible, so they cannot appear
! in CLASS(...).
module class_enumeration_m
  implicit none
  enumeration type :: colour
    enumerator :: red, green
  end enumeration type
  enumeration type :: fruit
    enumerator :: apple, pear
  end enumeration type
contains
  generic subroutine s(x)
    class(colour, fruit) :: x
  end subroutine
end module
