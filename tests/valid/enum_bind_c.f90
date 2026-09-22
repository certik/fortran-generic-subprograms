! TEST-RULE: R706 R771 R772 R775 R776 R1157
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
      if (x == colour(red)) then
        n = 11
      else if (x == colour(green)) then
        n = 12
      else
        n = -1
      end if
    declared type is (fruit)
      if (x == fruit(apple)) then
        n = 21
      else if (x == fruit(pear)) then
        n = 22
      else
        n = -2
      end if
    end select
  end function
end module

program enum_bind_c_p
  use enum_bind_c_m
  implicit none
  if (code(colour(red)) /= 11) error stop "colour red"
  if (code(colour(green)) /= 12) error stop "colour green"
  if (code(fruit(apple)) /= 21) error stop "fruit apple"
  if (code(fruit(pear)) /= 22) error stop "fruit pear"
end program
