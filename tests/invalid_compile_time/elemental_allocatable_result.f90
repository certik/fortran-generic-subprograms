! Invalid: C15136. The result of an elemental function is not allocatable.
module elemental_allocatable_result_m
  implicit none
contains
  elemental generic function f(x) result(y)
    integer, intent(in) :: x
    integer, allocatable :: y
    y = x
  end function
end module
