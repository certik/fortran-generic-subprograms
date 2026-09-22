! Invalid. One binding label cannot name both the integer specific and
! the real specific.
module bind_c_many_specifics_m
  implicit none
contains
  generic subroutine s(x) bind(c)
    type(integer, real), intent(in), value :: x
  end subroutine
end module
