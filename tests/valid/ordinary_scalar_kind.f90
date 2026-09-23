! TEST-RULE: R704 R708 C718 C801 C802 15.6.2.4
! TEST-REQUIRES: int32
! TEST-PASS: ordinary_scalar_kind
! A scalar kind is an ordinary type, not a type-generic dummy.
! INTEGER(INT32) cannot use the generic parse because C718 requires a rank-one
! kind expression. CHARACTER(LEN=*) is deliberately used only where the
! ordinary/generic parse does not affect the result; interpretation-dependent
! selection is isolated in draft_interpretations/valid.
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
  if (int32 < 0) error stop "need int32"
  if (mix("abcd", 3_int32, 10) /= 17) error stop "integer"
  if (mix("ab", 1_int32, 0.5) /= 4) error stop "real"
  if (mix("", 0_int32, 1) /= 1) error stop "empty"
  print '(a)', 'TEST-PASS: ordinary_scalar_kind'
end program
