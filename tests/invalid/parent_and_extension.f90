! Invalid: 15.4.3.4.5 and 7.3.3. CLASS(base) is TKR compatible with
! CLASS(child) when child extends base, so the specifics are not distinguishable.
! TYPE(base, child) would be legal; CLASS(base, child) is not.
module parent_and_extension_m
  implicit none
  type :: base
    integer :: n
  end type
  type, extends(base) :: child
    integer :: m
  end type
contains
  generic subroutine s(x)
    class(base, child) :: x
  end subroutine
end module
