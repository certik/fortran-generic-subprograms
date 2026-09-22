! TEST-RULE: C1561 C1564 15.4.3.2 15.4.3.4.1 15.6.2.6
! TEST-REQUIRES: int32 int64
! TEST-DRAFT: generic-interface-declarations
! Generic MODULE interface bodies contribute every generated specific to
! enclosing named and operator generics.
module integration_module_interface_routes_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
  interface routed
    module generic function routed_impl(x) result(y)
      integer([int64, int32, int64]), intent(in) :: x
      typeof(x) :: y
    end function
  end interface
  interface operator(.rankcode.)
    module generic function rank_impl(x) result(y)
      integer([int64, int32, int64]), rank(0:1), intent(in) :: x
      integer :: y
    end function
  end interface
end module
