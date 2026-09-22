! Enumeration types are generic-type-specifiers (R706). The guard's type-spec
! is the enumeration type name, not TYPE(name).
module enumeration_types_m
  implicit none
  enumeration type :: colour
    enumerator :: red, green
  end enumeration type
  enumeration type :: fruit
    enumerator :: apple, pear
  end enumeration type
contains
  generic function code(x) result(n)
    type(colour, fruit), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (colour)
      n = 1
    declared type is (fruit)
      n = 2
    end select
  end function
end module

program enumeration_types_p
  use enumeration_types_m
  implicit none
  if (code(red) /= 1) error stop "colour"
  if (code(apple) /= 2) error stop "fruit"
  if (code(green) /= 1) error stop "green"
end program
