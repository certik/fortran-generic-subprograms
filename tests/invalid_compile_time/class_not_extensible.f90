! Invalid: C715. CLASS generic specifiers must be extensible types.
module class_not_extensible_m
  implicit none
contains
  generic subroutine s(x)
    class(integer, real) :: x
  end subroutine
end module
