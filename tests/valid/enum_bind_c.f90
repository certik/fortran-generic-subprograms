! Interoperable enum types are generic-type-specifiers. Enumerators themselves
! are integers; values of the enum type are produced by an enum constructor.
module enum_bind_c_m
  implicit none
  enum, bind(c) :: colour
    enumerator :: red = 1, green = 2
  end enum
  enum, bind(c) :: fruit
    enumerator :: apple = 4, pear = 5
  end enum
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

program enum_bind_c_p
  use enum_bind_c_m
  implicit none
  if (code(colour(red)) /= 1) error stop "colour"
  if (code(fruit(pear)) /= 2) error stop "fruit"
end program
