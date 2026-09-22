! TEST-RULE: R705 R708 R710 R711 C717 C718 C803 C804 7.3.2.1 8.2
! All four gen-char-type-params forms, entity-level *(*) and *(:) overrides,
! assumed/deferred/pointer lengths, and scalar/array rank combinations.
! K2 selects a nondefault kind when one exists; on a one-kind processor it
! equals K1, and duplicate type/kind combinations collapse as specified.
! No SELECT GENERIC TYPE guard with an assumed length appears in this settled
! core; those interpretation-dependent guards are isolated and tagged.
module language_character_forms_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
  integer, parameter :: k1 = kind("A")
  integer, parameter :: k2_index = merge(2, 1, &
    size(character_kinds) > 1 .and. character_kinds(1) == k1)
  integer, parameter :: k2 = character_kinds(k2_index)
contains
  generic function positional(s) result(t)
    character(*, character_kinds), intent(in) :: s
    typeof(s) :: t
    t = s
  end function

  generic function positional_keyword(s) result(t)
    character(*, kind=character_kinds), intent(in) :: s
    typeof(s) :: t
    t = s
  end function

  generic function keyword_order(s) result(t)
    character(len=*, kind=character_kinds), intent(in) :: s
    typeof(s) :: t
    t = s
  end function

  generic function reverse_keyword_order(s) result(t)
    character(kind=character_kinds, len=*), intent(in) :: s
    typeof(s) :: t
    t = s
  end function

  generic subroutine copy_deferred(source, target)
    character(:, character_kinds), allocatable, intent(in) :: source
    typeof(source), allocatable, intent(out) :: target
    target = source
  end subroutine

  generic function deferred_positional_keyword_length(s) result(n)
    character(:, kind=character_kinds), allocatable, intent(in) :: s
    integer :: n
    n = len(s)
  end function

  generic function deferred_keyword_length(s) result(n)
    character(len=:, kind=character_kinds), allocatable, intent(in) :: s
    integer :: n
    n = len(s)
  end function

  generic function pointer_length(s) result(n)
    character(kind=character_kinds, len=:), pointer, intent(in) :: s
    integer :: n
    n = len(s)
  end function

  generic function entity_assumed(s) result(n)
    type(character(*, kind=[k1]), character(*, kind=[k2])), intent(in) :: s*(*)
    integer :: n
    n = 100*len(s) + kind(s)
  end function

  generic subroutine entity_deferred(s)
    type(character(*, kind=[k1]), character(*, kind=[k2])), allocatable, intent(out) :: s*(:)
    s = "ok"
  end subroutine

  generic function rank_code(s) result(n)
    character(len=*, kind=[k1, k2]), rank(0:1), intent(in) :: s
    integer :: n
    select generic rank (s)
    rank (0)
      n = 100 + len(s)
    rank (1)
      n = 200 + 10*size(s) + len(s)
    end select
  end function
end module

program language_character_forms_p
  use, intrinsic :: iso_fortran_env, only: character_kinds
  use language_character_forms_m
  implicit none
  integer, parameter :: other = k2
  character(len=4) :: d
  character(kind=other, len=4) :: d2, expected2
  character(len=:), allocatable :: ad, bd, ed
  character(kind=other, len=:), allocatable :: a2, b2, e2
  character(len=3), target :: td
  character(kind=other, len=3), target :: t2
  character(len=:), pointer :: pd
  character(kind=other, len=:), pointer :: p2
  character(len=2) :: da(2)
  character(kind=other, len=2) :: a2d(2), a2e(2)

  d = "ABCD"
  d2 = "ABCD"
  expected2 = "ABCD"
  if (positional(d) /= d .or. positional(d2) /= expected2) error stop "positional"
  if (positional_keyword(d) /= d .or. positional_keyword(d2) /= expected2) &
    error stop "positional keyword"
  if (keyword_order(d) /= d .or. keyword_order(d2) /= expected2) error stop "keyword order"
  if (reverse_keyword_order(d) /= d .or. reverse_keyword_order(d2) /= expected2) &
    error stop "reverse keyword order"
  if (kind(positional(d2)) /= other) error stop "selected result kind"

  ad = "hello"
  a2 = "world"
  call copy_deferred(ad, bd)
  call copy_deferred(a2, b2)
  if (.not. allocated(bd)) error stop "deferred default allocation"
  if (.not. allocated(b2)) error stop "deferred selected allocation"
  if (bd /= ad .or. len(bd) /= 5) error stop "deferred default"
  if (b2 /= a2 .or. len(b2) /= 5) error stop "deferred selected"
  if (kind(b2) /= other) error stop "deferred selected kind"
  if (deferred_positional_keyword_length(ad) /= 5) error stop "deferred positional keyword"
  if (deferred_positional_keyword_length(a2) /= 5) error stop "deferred positional keyword selected"
  if (deferred_keyword_length(ad) /= 5) error stop "deferred keyword"
  if (deferred_keyword_length(a2) /= 5) error stop "deferred keyword selected"

  td = "abc"
  t2 = "xyz"
  pd => td
  p2 => t2
  if (pointer_length(pd) /= 3) error stop "pointer default"
  if (pointer_length(p2) /= 3) error stop "pointer selected"
  if (entity_assumed(d) /= 400 + kind(d)) error stop "entity assumed default"
  if (entity_assumed(d2) /= 400 + other) error stop "entity assumed selected"

  call entity_deferred(ed)
  call entity_deferred(e2)
  if (.not. allocated(ed)) error stop "entity deferred default allocation"
  if (.not. allocated(e2)) error stop "entity deferred selected allocation"
  if (len(ed) /= 2 .or. ed /= "ok") error stop "entity deferred default"
  if (len(e2) /= 2 .or. kind(e2) /= other) error stop "entity deferred selected"

  da = ["ab", "cd"]
  a2d(1) = "ab"
  a2d(2) = "cd"
  a2e(1) = "ab"
  a2e(2) = "cd"
  if (rank_code(d) /= 104) error stop "character scalar rank"
  if (rank_code(d2) /= 104) error stop "character scalar selected rank"
  if (rank_code(da) /= 222) error stop "character array rank"
  if (rank_code(a2d) /= 222) error stop "character array selected rank"
  if (any(a2d /= a2e)) error stop "character array values"
end program
