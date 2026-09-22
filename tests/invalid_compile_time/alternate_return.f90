! Invalid: C1584. A generic subprogram shall not have an asterisk dummy.
module alternate_return_m
  implicit none
contains
  generic subroutine s(*)
  end subroutine
end module
