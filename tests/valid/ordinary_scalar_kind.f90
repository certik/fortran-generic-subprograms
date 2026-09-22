! A scalar kind is an ordinary type, not a type-generic dummy.
! CHARACTER(LEN=*) with no kind array is ordinary assumed-length character.
! The generic parse of those spellings is not used: INTEGER(INT32) is the
! long-standing kind selector, and CHARACTER(LEN=*) is the long-standing
! assumed-length specifier. SELECT GENERIC TYPE on either is rejected by
! the invalid_compile_time tests select_on_scalar_kind and
! select_on_assumed_character.
module ordinary_scalar_kind_m
  use, intrinsic :: iso_fortran_env, only: int32
  implicit none
contains
  generic function mix(s, n, x) result(k)
    character(len=*), intent(in) :: s
    integer(int32), intent(in) :: n
    type(integer, real), intent(in) :: x
    integer :: k
    k = len(s) + int(n)
    select generic type (x)
    declared type is (integer)
      k = k + x
    declared type is (real)
      k = k + 1
    end select
  end function
end module

program ordinary_scalar_kind_p
  use, intrinsic :: iso_fortran_env, only: int32
  use ordinary_scalar_kind_m
  implicit none
  if (int32 <= 0) error stop "need int32"
  if (mix("abcd", 3_int32, 10) /= 17) error stop "integer"
  if (mix("ab", 1_int32, 0.5) /= 4) error stop "real"
  if (mix("", 0_int32, 1) /= 1) error stop "empty"
end program
