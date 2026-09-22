! Invalid: C15135. An elemental dummy is not allocatable.
module elemental_allocatable_m
  implicit none
contains
  elemental generic subroutine s(x)
    integer, allocatable, intent(inout) :: x
    x = 1
  end subroutine
end module
