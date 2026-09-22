! GENERIC is allowed on an ordinary module procedure in a submodule, not
! only on a separate module procedure. The separate procedure here is run;
! plus1 is a sibling module procedure in the submodule (C1564, 3.143.4).
module submodule_procedure_m
  implicit none
  interface
    module function run() result(n)
      integer :: n
    end function
  end interface
end module

submodule (submodule_procedure_m) submodule_procedure_s
  implicit none
contains
  module function run() result(n)
    integer :: n
    n = plus1(4)
    if (plus1(1.5) /= 2.5) error stop "real"
  end function

  generic function plus1(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + 1
  end function
end submodule

program submodule_procedure_p
  use submodule_procedure_m
  implicit none
  if (run() /= 5) error stop "integer"
end program
