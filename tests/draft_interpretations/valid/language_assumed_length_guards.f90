! TEST-RULE: C736 C7124 C1160 R1157 7.2 11.1.11
! TEST-DRAFT: assumed-length-guards
! TEST-PASS: language_assumed_length_guards
! C1160 requires assumed length parameters in a generic type guard, while the
! older assumed-length context constraints do not clearly name that guard.
! This portable part needs only default character and user-defined PDT kind
! values. Guards that distinguish two character kinds are isolated in
! language_assumed_length_guards_character_kinds.f90, the only part that
! needs a second character kind.
module language_assumed_length_guards_m
  implicit none
  integer, parameter :: kd = kind("A")
  type :: item(k, n)
    integer, kind :: k
    integer, len :: n
    integer :: value(n)
  end type
contains
  generic function character_or_integer(s) result(n)
    type(character(len=*), integer), intent(in) :: s
    integer :: n
    select generic type (s)
    declared type is (character(len=*))
      n = 100 + len(s)
    declared type is (integer)
      n = 300 + s
    end select
  end function

  generic function default_kind_guard(s) result(n)
    character(len=*, kind=[kd]), intent(in) :: s
    integer :: n
    n = -1
    select generic type (s)
    declared type is (character(len=*, kind=kd))
      n = 200 + len(s)
    end select
  end function

  generic subroutine allocate_item(x)
    type(item(k=[1, 2], n=:)), allocatable, intent(out) :: x
    select generic type (x)
    declared type is (item(k=1, n=*))
      allocate(item(k=1, n=2) :: x)
      x%value = [3, 4]
    declared type is (item(k=2, n=*))
      allocate(item(k=2, n=3) :: x)
      x%value = [5, 6, 7]
    end select
  end subroutine
end module

program language_assumed_length_guards_p
  use language_assumed_length_guards_m
  implicit none
  type(item(k=1, n=:)), allocatable :: a
  type(item(k=2, n=:)), allocatable :: b

  if (character_or_integer("abcd") /= 104) error stop "default character guard"
  if (character_or_integer(7) /= 307) error stop "integer beside character guard"
  if (default_kind_guard("xyz") /= 203) error stop "one-kind character guard"
  call allocate_item(a)
  call allocate_item(b)
  if (.not. allocated(a)) error stop "PDT assumed guard kind1 allocation"
  if (.not. allocated(b)) error stop "PDT assumed guard kind2 allocation"
  if (a%n /= 2 .or. any(a%value /= [3, 4])) error stop "PDT assumed guard kind1"
  if (b%n /= 3 .or. any(b%value /= [5, 6, 7])) error stop "PDT assumed guard kind2"
  print '(a)', 'TEST-PASS: language_assumed_length_guards'
end program
