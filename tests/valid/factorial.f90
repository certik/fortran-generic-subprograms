! 15.6.2.4 NOTE 6. n-1 has the same type and kind as n, so the recursive
! reference resolves to the same specific. 0 and 1 both return 1.
module factorial_m
  use, intrinsic :: iso_fortran_env, only: integer_kinds, int32, int64
  implicit none
contains
  generic recursive function factorial(n) result(res)
    integer(integer_kinds) :: n
    typeof(n) :: res
    if (n > 1) then
      res = n * factorial(n - 1)
    else if (n < 0) then
      error stop "factorial is not defined for negative numbers"
    else
      res = 1
    end if
  end function
end module

program factorial_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use factorial_m
  implicit none
  integer(int64), parameter :: fact13 = 6227020800_int64
  if (int32 <= 0 .or. int64 <= 0) error stop "need int32 and int64"
  if (factorial(0) /= 1) error stop "0!"
  if (factorial(1_int32) /= 1_int32) error stop "1!"
  if (factorial(5) /= 120) error stop "5!"
  if (factorial(5_int32) /= 120_int32) error stop "5! int32"
  if (factorial(13_int64) /= fact13) error stop "13! int64"
  if (kind(factorial(13_int64)) /= int64) error stop "kind"
end program
