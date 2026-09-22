! A module generic may contain an internal procedure that uses TYPEOF of the
! host generic dummy. A generic may also be internal to a non-generic host
! and touch a host variable (C1582, C1583). An internal subprogram cannot
! itself contain an internal subprogram, so those two shapes are separate.
module internal_host_m
  implicit none
contains
  generic function twice(n) result(r)
    type(integer, real), intent(in) :: n
    typeof(n) :: r
    r = add(n, n)
  contains
    function add(a, b) result(c)
      typeof(n), intent(in) :: a, b
      typeof(n) :: c
      c = a + b
    end function
  end function
end module

program internal_host_p
  use internal_host_m
  implicit none
  integer :: calls
  calls = 0
  if (twice(3) /= 6) error stop "integer"
  if (twice(1.5) /= 3.0) error stop "real"
  if (bump(3) /= 4) error stop "internal integer"
  if (bump(1.5) /= 2.5) error stop "internal real"
  if (calls /= 2) error stop "host association"
contains
  generic function bump(n) result(r)
    type(integer, real), intent(in) :: n
    typeof(n) :: r
    r = n + 1
    calls = calls + 1
  end function
end program
