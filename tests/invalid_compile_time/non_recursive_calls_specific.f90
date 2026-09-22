! Invalid: 15.6.2.1 p3. NON_RECURSIVE forbids any specific from calling any
! specific of the same subprogram. This is not a numbered constraint; the
! suite still rejects it.
module non_recursive_calls_specific_m
  implicit none
contains
  non_recursive generic function widen(x) result(y)
    type(integer, real), intent(in) :: x
    real :: y
    select generic type (x)
    declared type is (integer)
      y = widen(real(x))
    declared type is (real)
      y = x
    end select
  end function
end module
