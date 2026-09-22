! Invalid under the reading used by this suite. BIND(C) gives one binding
! label to one procedure. A generic subprogram's specifics are unnamed, and
! its name is a generic identifier, even when there is only one specific.
module bind_c_one_specific_m
  implicit none
contains
  generic subroutine s(x) bind(c)
    integer, intent(in), value :: x
  end subroutine
end module
