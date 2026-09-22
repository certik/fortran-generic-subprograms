! TEST-RULE: R708 R710 R711 C717 C718 7.3.2.1 15.6.2.4
! TEST-REQUIRES: ascii
! CHARACTER(LEN=*, KIND=CHARACTER_KINDS) and deferred length (C717).
! KIND(s) in a kind selector is a constant expression inside each specific.
module character_kinds_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
contains
  generic function len_of(s) result(n)
    character(len=*, kind=character_kinds), intent(in) :: s
    integer :: n
    n = len(s)
  end function

  generic function dub(s) result(t)
    character(len=*, kind=character_kinds), intent(in) :: s
    character(len=len(s)*2, kind=kind(s)) :: t
    t = s // s
  end function

  generic subroutine set_msg(s)
    character(len=:, kind=character_kinds), allocatable, intent(out) :: s
    s = "hi"
  end subroutine

  ! TYPEOF of an assumed-length character takes that length. The result is
  ! not itself assumed-length (7.3.2.1 p3). An assumed-length function result
  ! is not allowed here, so a successful return is the check.
  generic function same(s) result(t)
    character(len=*, kind=character_kinds), intent(in) :: s
    typeof(s) :: t
    t = s
  end function

  ! TYPEOF of a deferred length stays deferred, so the result is allocatable.
  generic function clone(s) result(t)
    character(len=:, kind=character_kinds), allocatable, intent(in) :: s
    typeof(s), allocatable :: t
    t = s
  end function
end module

program character_kinds_p
  use character_kinds_m
  implicit none
  integer, parameter :: ascii = selected_char_kind("ASCII")
  character(kind=ascii, len=2) :: sa
  character(len=:), allocatable :: d, copied
  if (len_of("hello") /= 5) error stop "len"
  if (len_of("") /= 0) error stop "len empty"
  if (dub("ab") /= "abab") error stop "dub"
  call set_msg(d)
  if (.not. allocated(d)) error stop "deferred allocated"
  if (d /= "hi") error stop "deferred value"
  if (len(d) /= 2) error stop "deferred len"
  if (kind(d) /= kind("A")) error stop "deferred kind"
  if (same("ab") /= "ab") error stop "typeof assumed"
  if (len(same("ab")) /= 2) error stop "typeof length"
  if (len(same("")) /= 0) error stop "typeof empty"
  if (kind(same("ab")) /= kind("A")) error stop "typeof kind"
  d = "xyz"
  copied = clone(d)
  if (.not. allocated(copied)) error stop "clone assignment allocated"
  if (copied /= "xyz") error stop "clone assignment value"
  if (len(copied) /= 3) error stop "clone assignment length"
  if (clone(d) /= "xyz") error stop "clone value"
  if (len(clone(d)) /= 3) error stop "clone keeps deferred length"
  if (kind(clone(d)) /= kind(d)) error stop "clone keeps deferred kind"
  if (ascii < 0) error stop "ASCII character kind"
  sa = "ab"
  if (len_of(sa) /= 2) error stop "ascii len"
  if (same(sa) /= sa) error stop "ascii typeof"
  if (kind(same(sa)) /= ascii) error stop "ascii kind"
end program
