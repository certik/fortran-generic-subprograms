! Invalid: C1512. A GENERIC statement shall not give a generic name another
! generic name as a specific.
module generic_stmt_generic_name_m
  implicit none
  generic :: g => f
contains
  generic subroutine f(x)
    type(integer, real) :: x
  end subroutine
end module
