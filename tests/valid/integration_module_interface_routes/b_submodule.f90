submodule (integration_module_interface_routes_m) &
    integration_module_interface_routes_s
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
contains
  module generic function routed_impl(x) result(y)
    integer([int32, int64]), intent(in) :: x
    typeof(x) :: y
    y = x + 1
  end function

  module generic function rank_impl(x) result(y)
    integer([int32, int64]), rank(1, 0, 1), intent(in) :: x
    integer :: y
    select generic rank (x)
    rank (0)
      y = x
    rank (1)
      y = 100 + sum(x)
    end select
  end function
end submodule
