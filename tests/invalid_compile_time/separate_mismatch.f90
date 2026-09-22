! Invalid: C1561. The interface and the defining subprogram expand to
! different sets of specifics.
module separate_mismatch_m
  implicit none
  interface
    module generic function id(x) result(y)
      type(integer, real), intent(in) :: x
      typeof(x) :: y
    end function
  end interface
end module

submodule (separate_mismatch_m) separate_mismatch_s
contains
  module generic function id(x) result(y)
    type(integer, complex), intent(in) :: x
    typeof(x) :: y
    y = x
  end function
end submodule
