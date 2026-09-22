! TEST-RULE: C736 C7124 C1160 R1157 7.2 11.1.11
! TEST-DRAFT: assumed-length-guards
! TEST-REQUIRES: character_kinds>=2
! C1160 requires assumed length parameters in a generic type guard, while the
! older assumed-length context constraints do not clearly name that guard.
module language_assumed_length_guards_m
  use, intrinsic :: iso_fortran_env, only: character_kinds
  implicit none
  integer, parameter :: k1 = kind("A")
  integer, parameter :: k2 = character_kinds(merge(1, 2, character_kinds(1) /= k1))
  type :: item(k, n)
    integer, kind :: k
    integer, len :: n
    integer :: value(n)
  end type
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
  use, intrinsic :: iso_fortran_env, only: character_kinds
  use language_assumed_length_guards_m
  implicit none
  integer, parameter :: other = k2
  character(kind=other, len=3) :: s2
  type(item(k=1, n=:)), allocatable :: a
  type(item(k=2, n=:)), allocatable :: b

  s2 = "abc"
  if (character_guard("abcd") /= 104) error stop "default character guard"
  if (character_guard(s2) /= 203) error stop "other character guard"
  call allocate_item(a)
  call allocate_item(b)
  if (.not. allocated(a)) error stop "PDT assumed guard kind1 allocation"
  if (.not. allocated(b)) error stop "PDT assumed guard kind2 allocation"
  if (a%n /= 2 .or. any(a%value /= [3, 4])) error stop "PDT assumed guard kind1"
  if (b%n /= 3 .or. any(b%value /= [5, 6, 7])) error stop "PDT assumed guard kind2"
end program
