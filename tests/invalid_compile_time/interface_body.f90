! Invalid: C1564. An interface body may have GENERIC only together with MODULE.
module interface_body_m
  implicit none
  interface
    generic subroutine s(x)
      integer, rank(0:1) :: x
    end subroutine
  end interface
end module
