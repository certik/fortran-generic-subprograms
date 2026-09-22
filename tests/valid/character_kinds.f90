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

  generic function is_default_kind(s) result(ans)
    character(len=*, kind=character_kinds), intent(in) :: s
    logical :: ans
    select generic type (s)
    declared type is (character(len=*, kind=kind("A")))
      ans = .true.
    declared type default
      ans = .false.
    end select
  end function
end module

program character_kinds_p
  use character_kinds_m
  implicit none
  character(len=:), allocatable :: d
  if (len_of("hello") /= 5) error stop "len"
  if (len_of("") /= 0) error stop "len empty"
  if (dub("ab") /= "abab") error stop "dub"
  if (.not. is_default_kind("a")) error stop "default kind guard"
  call set_msg(d)
  if (.not. allocated(d)) error stop "deferred allocated"
  if (d /= "hi") error stop "deferred value"
  if (len(d) /= 2) error stop "deferred len"
  if (kind(d) /= kind("A")) error stop "deferred kind"
end program
