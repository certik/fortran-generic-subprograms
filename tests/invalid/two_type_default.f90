! Invalid: C1162. At most one DECLARED TYPE DEFAULT.
! The constraint text says "TYPE DEFAULT"; the syntax is DECLARED TYPE DEFAULT.
module two_type_default_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    declared type default
      x = 1
    declared type default
      x = 2
    end select
  end subroutine
end module
