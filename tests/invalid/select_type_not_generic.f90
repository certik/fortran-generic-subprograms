! Invalid: C1159. A plain INTEGER dummy is not type-generic.
module select_type_not_generic_m
  implicit none
contains
  generic subroutine s(x)
    integer :: x
    select generic type (x)
    declared type is (integer)
      x = 1
    end select
  end subroutine
end module
