! TEST-RULE: R706 R777 R780 R782 R783 R1157
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
      if (x == red) then
        n = 11
      else if (x == green) then
        n = 12
      else
        n = -1
      end if
    declared type is (fruit)
      if (x == apple) then
        n = 21
      else if (x == pear) then
        n = 22
      else
        n = -2
      end if
    end select
  end function
end module

program enumeration_types_p
  use enumeration_types_m
  implicit none
  if (code(red) /= 11) error stop "colour enumerator"
  if (code(green) /= 12) error stop "green enumerator"
  if (code(apple) /= 21) error stop "fruit enumerator"
  if (code(pear) /= 22) error stop "pear enumerator"
  if (code(colour(1)) /= 11) error stop "colour constructor"
  if (code(fruit(2)) /= 22) error stop "fruit constructor"
  if (code(colour%green) /= 12) error stop "scoped enumerator"
end program
