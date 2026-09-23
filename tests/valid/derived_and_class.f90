! TEST-RULE: R705 C715 C716 R1155 R1157 7.3.3 11.1.11
! TEST-PASS: derived_and_class
! TYPE of a parent and its extension is distinguishable.
! CLASS of two unrelated types is distinguishable; the guard sees the declared
! type, and SELECT TYPE inside it sees the dynamic type (7.3.3, 11.1.11).
! CLASS(base), RANK(0:1) is rank-generic only: CLASS(base) is an ordinary
! polymorphic type spec (C716 does not make a one-item list generic).
module derived_and_class_m
  implicit none
  type :: base
    integer :: n = 1
  end type
  type, extends(base) :: child
    integer :: m = 2
  end type
  type :: other
    integer :: n = 0
  end type
  type, extends(base) :: extra
    integer :: k = 9
  end type
contains
  generic function which_type(x) result(k)
    type(base, child), intent(in) :: x
    integer :: k
    select generic type (x)
    declared type is (base)
      k = 1
    declared type is (child)
      k = x%m
    end select
  end function

  generic function which_class(x) result(k)
    class(base, other), intent(in) :: x
    integer :: k
    select generic type (x)
    declared type is (base)
      select type (x)
      type is (base)
        k = 1
      class is (base)
        k = 3
      end select
    declared type is (other)
      k = 2
    end select
  end function

  generic function rank_of_poly(x) result(n)
    class(base), rank(0:1), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      n = 0
    rank (1)
      n = 1
    end select
  end function
end module

program derived_and_class_p
  use derived_and_class_m
  implicit none
  type(base) :: b
  type(child) :: c
  type(other) :: o
  type(base) :: row(2)
  class(base), allocatable :: p
  b%n = 4
  c%n = 4
  c%m = 7
  if (which_type(b) /= 1) error stop "type base"
  if (which_type(c) /= 7) error stop "type child"
  if (which_class(b) /= 1) error stop "class base"
  if (which_class(o) /= 2) error stop "class other"
  allocate(extra :: p)
  if (which_class(p) /= 3) error stop "dynamic extension"
  if (rank_of_poly(b) /= 0) error stop "poly scalar"
  if (rank_of_poly(row) /= 1) error stop "poly rank1"
  print '(a)', 'TEST-PASS: derived_and_class'
end program
