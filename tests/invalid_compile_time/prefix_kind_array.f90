! Invalid syntax. A prefix type is a declaration-type-spec. A generic kind
! array is not a kind-selector. Declare the result with TYPEOF in the body.
module prefix_kind_array_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
contains
  generic integer([int32, int64]) function f(x)
    integer([int32, int64]), intent(in) :: x
    f = x
  end function
end module
