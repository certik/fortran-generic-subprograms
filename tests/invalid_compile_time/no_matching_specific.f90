! Invalid. The actual is logical. Neither specific of s accepts it.
module no_matching_specific_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
  end subroutine
end module

program no_matching_specific_p
  use no_matching_specific_m
  implicit none
  call s(.true.)
end program
