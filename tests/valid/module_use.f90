! A module generic is use-associated. The caller does not redeclare it.
module module_use_m
  implicit none
contains
  generic function twice(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    block
      typeof(x) :: tmp
      tmp = x
      y = tmp + tmp
    end block
  end function
end module

program module_use_p
  use module_use_m
  implicit none
  if (twice(21) /= 42) error stop "integer"
  if (twice(1.25) /= 2.5) error stop "real"
end program
