! TEST-RULE: R705 R706 R707 R708 R712 C716 C718 C723 7.3.2.2
! TEST-REQUIRES: integer_kinds>=2
! TEST-PASS: language_kind_dedup
! Deduplication here is within one kind array or one TYPE list. It does not
! merge indistinguishable specifics contributed by separate procedures.
module language_kind_origin_m
  implicit none
  type :: token
    integer :: value
  end type
end module

module language_kind_left_m
  use language_kind_origin_m, only: left => token
  implicit none
  public :: left
end module

module language_kind_right_m
  use language_kind_origin_m, only: right => token
  implicit none
  public :: right
end module

module language_kind_dedup_m
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  use language_kind_left_m, only: left
  use language_kind_right_m, only: right
  implicit none
  integer, parameter :: kfirst = integer_kinds(1)
  integer, parameter :: klast = integer_kinds(size(integer_kinds))
  integer, parameter :: pool(-2:3) = [kfirst, kfirst, klast, klast, kfirst, klast]
  type :: marker(k)
    integer, kind :: k
    integer :: value
  end type
contains
  generic function dedup_integer(x) result(y)
    type(integer(pool(-2:3:2)), integer(kfirst), integer([klast, kfirst])), intent(in) :: x
    typeof(x) :: y
    y = -x
  end function

  generic function alias_code(x) result(n)
    type(left, right), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (left)
      n = x%value
    end select
  end function

  generic function marker_code(x) result(n)
    type(marker(k=[0, 0, -3, 0, -3])), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (marker(k=0))
      n = 100 + x%value
    declared type is (marker(k=-3))
      n = 200 + x%value
    end select
  end function
end module

program language_kind_dedup_p
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  use language_kind_origin_m, only: token
  use language_kind_dedup_m
  implicit none
  integer, parameter :: k1 = integer_kinds(1)
  integer, parameter :: k2 = integer_kinds(size(integer_kinds))
  integer(k1) :: a
  integer(k2) :: b
  type(token) :: t
  type(marker(0)) :: m0
  type(marker(-3)) :: mn

  ! INTEGER_KINDS order is processor dependent and an extra kind may be very
  ! narrow, so only 1 and -1 are used: every integer kind represents them.
  a = int(1, kind=k1)
  b = int(1, kind=k2)
  if (dedup_integer(a) /= int(-1, kind=k1)) error stop "section kind first"
  if (dedup_integer(b) /= int(-1, kind=k2)) error stop "section kind last"
  if (kind(dedup_integer(a)) /= k1) error stop "dedup first kind"
  if (kind(dedup_integer(b)) /= k2) error stop "dedup last kind"
  t%value = 37
  if (alias_code(t) /= 37) error stop "derived aliases identify one type"
  m0%value = 5
  mn%value = 7
  if (marker_code(m0) /= 105) error stop "user kind zero"
  if (marker_code(mn) /= 207) error stop "user kind negative"
  print '(a)', 'TEST-PASS: language_kind_dedup'
end program
