! TEST-RULE: 15.6.2.4 NOTE6 11.4
! TEST-REQUIRES: int32
! TEST-STOP: factorial-negative
! The negative branch of 15.6.2.4 NOTE 6 is intentional error termination.
! This program is conforming and is expected to end with error stop.
program factorial_negative_p
  use, intrinsic :: iso_fortran_env, only: int32, output_unit
  implicit none
  call run(-1_int32)
contains
  generic recursive function factorial(n) result(res)
    use, intrinsic :: iso_fortran_env, only: integer_kinds
    integer(integer_kinds) :: n
    typeof(n) :: res
    if (n > 1) then
      res = n * factorial(n - 1)
    else if (n < 0) then
      print '(a)', "TEST-STOP: factorial-negative"
      flush(output_unit)
      error stop "factorial is not defined for negative numbers"
    else
      res = 1
    end if
  end function
  subroutine run(n)
    integer(int32), intent(in) :: n
    integer(int32) :: ignored
    ignored = factorial(n)
    print '(a)', "TEST-UNEXPECTED-RETURN: factorial-negative"
  end subroutine
end program
