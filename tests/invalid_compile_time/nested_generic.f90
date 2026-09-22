! Invalid: C1583. An internal subprogram of a generic subprogram shall not
! be generic.
module nested_generic_m
  implicit none
contains
  generic subroutine outer(x)
    integer, rank(0:1) :: x
  contains
    generic subroutine inner(y)
      integer :: y
    end subroutine
  end subroutine
end module
