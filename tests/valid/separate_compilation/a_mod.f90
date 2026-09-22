! Compiled before the program that uses it. Every specific has to be
! available to that later compilation (15.6.2.4).
module separate_compilation_m
  implicit none
contains
  generic function tag(x) result(n)
    type(integer, real), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer)
      n = 1
    declared type is (real)
      n = 2
    end select
  end function
end module
