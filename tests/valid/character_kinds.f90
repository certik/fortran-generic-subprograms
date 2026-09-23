! TEST-RULE: R708 R710 R711 C717 C718 7.3.2.1 15.6.2.4
! TEST-REQUIRES: ascii
! TEST-PASS: character_kinds
! CHARACTER(LEN=*, KIND=CHARACTER_KINDS) and deferred length (C717).
! KIND(s) in a kind selector is a constant expression inside each specific.
! Every CHARACTER_KINDS specific must conform, and intrinsic assignment
! converts a default character value only to the default, ASCII, or ISO 10646
! kind (10.2.1.2), so SET_MSG builds its text with CHAR in the specific's kind.
module character_kinds_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
  integer, parameter :: ascii_kind = selected_char_kind("ASCII")
  integer, parameter :: ucs4_kind = selected_char_kind("ISO_10646")
contains
  ! Ordinal of the default character C in character kind K: ICHAR for the
  ! default kind (also the system kind here, 7.4.4.2 p3), the ASCII code (also
  ! the ISO 10646 code point) for the ASCII and ISO 10646 kinds (7.4.4.4 p4),
  ! and 0 for any other kind, whose repertoire is not specified but whose
  ! collating sequence contains 0.
  pure integer function text_ordinal(c, k) result(ordinal)
    character(len=1), intent(in) :: c
    integer, intent(in) :: k
    if (k == kind("A")) then
      ordinal = ichar(c)
    else if (k == ascii_kind .or. k == ucs4_kind) then
      ordinal = iachar(c)
    else
      ordinal = 0
    end if
  end function

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
    s = char(text_ordinal("h", kind(s)), kind=kind(s)) // &
      char(text_ordinal("i", kind(s)), kind=kind(s))
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
  character(kind=ascii, len=:), allocatable :: ascii_msg
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
  call set_msg(ascii_msg)
  if (.not. allocated(ascii_msg)) error stop "ascii deferred allocated"
  if (len(ascii_msg) /= 2 .or. kind(ascii_msg) /= ascii) error stop "ascii deferred shape"
  if (ascii_msg /= ascii_"hi") error stop "ascii deferred value"
  print '(a)', 'TEST-PASS: character_kinds'
end program
