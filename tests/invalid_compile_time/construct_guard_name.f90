! Invalid: C1163. A type guard names the construct and SELECT does not.
module construct_guard_name_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    select generic type (x)
    declared type is (integer) gr
      x = 1
    end select
  end subroutine
end module
