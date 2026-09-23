! TEST-RULE: C1582 C1583 15.6.2.4 15.6.2.5
! TEST-PASS: internal_host
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

  ! The internal procedure is cloned with the generic host. Its SAVE local
  ! is therefore independent for the integer and real host specifics.
  generic function cloned_counter(n) result(r)
    type(integer, real), intent(in) :: n
    integer :: r
    r = next()
  contains
    integer function next()
      integer, save :: calls = 0
      calls = calls + 1
      next = calls
    end function
  end function

  ! The ordinary host's SAVE local is shared across invocations, while the
  ! internal generic's SAVE local remains separate for each generated type.
  integer function ordinary_host(use_real) result(code)
    logical, intent(in) :: use_real
    integer, save :: host_calls = 0
    host_calls = host_calls + 1
    if (use_real) then
      code = 100*host_calls + local_touch(1.0)
    else
      code = 100*host_calls + local_touch(1)
    end if
  contains
    generic integer function local_touch(x)
      type(integer, real), intent(in) :: x
      integer, save :: specific_calls = 0
      specific_calls = specific_calls + 1
      local_touch = specific_calls
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
  if (cloned_counter(1) /= 1) error stop "cloned integer first"
  if (cloned_counter(2) /= 2) error stop "cloned integer second"
  if (cloned_counter(1.0) /= 1) error stop "cloned real first"
  if (cloned_counter(2.0) /= 2) error stop "cloned real second"
  if (ordinary_host(.false.) /= 101) error stop "ordinary host integer first"
  if (ordinary_host(.true.) /= 201) error stop "ordinary host real first"
  if (ordinary_host(.false.) /= 302) error stop "ordinary host integer second"
  if (ordinary_host(.true.) /= 402) error stop "ordinary host real second"
  if (bump(3) /= 4) error stop "internal integer"
  if (bump(1.5) /= 2.5) error stop "internal real"
  if (calls /= 2) error stop "host association"
  print '(a)', 'TEST-PASS: internal_host'
contains
  generic function bump(n) result(r)
    type(integer, real), intent(in) :: n
    typeof(n) :: r
    r = n + 1
    calls = calls + 1
  end function
end program
