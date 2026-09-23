! TEST-RULE: C736 C7124 C1160 R1157 7.2 11.1.11
! TEST-DRAFT: assumed-length-guards
! TEST-REQUIRES: character_kinds>=2
! TEST-PASS: language_assumed_length_guards_character_kinds
! C1160 requires assumed length parameters in a generic type guard, while the
! older assumed-length context constraints do not clearly name that guard.
! This split-out part selects between two character kinds, so it alone needs
! a second character kind; the portable default-character and PDT guards are
! in language_assumed_length_guards.f90.
module language_assumed_length_guards_character_kinds_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
  integer, parameter :: k1 = kind("A")
  integer, parameter :: k2 = character_kinds(merge(1, 2, character_kinds(1) /= k1))
contains
  generic function character_guard(s) result(n)
    character(len=*, kind=[k1, k2]), intent(in) :: s
    integer :: n
    select generic type (s)
    declared type is (character(len=*, kind=k1))
      n = 100 + len(s)
    declared type is (character(len=*, kind=k2))
      n = 200 + len(s)
    end select
  end function
end module

program language_assumed_length_guards_character_kinds_p
  use language_assumed_length_guards_character_kinds_m
  implicit none
  integer, parameter :: other = k2
  integer, parameter :: ascii_kind = selected_char_kind("ASCII")
  integer, parameter :: ucs4_kind = selected_char_kind("ISO_10646")
  ! OTHER can be any processor kind, and intrinsic assignment converts a
  ! default character value only to the default, ASCII, or ISO 10646 kind
  ! (10.2.1.2). The ordinal of "a" is therefore selected as an integer before
  ! CHAR is applied: ICHAR for the default (here also system) kind, the ASCII
  ! code for the ASCII and ISO 10646 kinds, and 0, present in every collating
  ! sequence, otherwise.
  integer, parameter :: a_ordinal = merge(ichar("a"), merge(iachar("a"), 0, &
    other == ascii_kind .or. other == ucs4_kind), other == k1)
  character(kind=other, len=3) :: s2

  s2 = repeat(char(a_ordinal, kind=other), 3)
  if (character_guard("abcd") /= 104) error stop "default character guard"
  if (character_guard(s2) /= 203) error stop "other character guard"
  print '(a)', 'TEST-PASS: language_assumed_length_guards_character_kinds'
end program
