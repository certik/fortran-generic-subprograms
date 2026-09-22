! Invalid syntax. 25-156r1 used TYPE IS. 26-007r1 uses DECLARED TYPE IS.
module type_is_syntax_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    type is (integer)
      x = 1
    end select
  end subroutine
end module
