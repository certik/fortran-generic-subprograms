! CLASSOF(x) has the declared type of x and is polymorphic. It is not a
! generic dummy and does not add a combination (7.3.2.1).
module classof_dependent_m
  implicit none
  type :: base
    integer :: n = 1
  end type
  type, extends(base) :: child
    integer :: m = 2
  end type
contains
  generic subroutine copy(x, y)
    type(base, child), intent(in) :: x
    classof(x), allocatable, intent(out) :: y
    allocate(y, source=x)
  end subroutine

  generic function dyn(x) result(k)
    type(base, child), intent(in) :: x
    classof(x), allocatable :: y
    integer :: k
    allocate(y, source=x)
    ! SELECT TYPE is checked per specific. TYPE IS (BASE) is legal only in
    ! the base specific, where y is CLASS(BASE).
    select generic type (x)
    declared type is (base)
      select type (y)
      type is (base)
        k = 1
      class is (base)
        k = 3
      end select
    declared type is (child)
      select type (y)
      type is (child)
        k = y%m
      class default
        k = 3
      end select
    end select
  end function
end module

program classof_dependent_p
  use classof_dependent_m
  implicit none
  type(base) :: b
  type(child) :: c
  class(base), allocatable :: yb
  class(child), allocatable :: yc
  b%n = 4
  c%n = 5
  c%m = 6
  call copy(b, yb)
  call copy(c, yc)
  if (.not. allocated(yb)) error stop "base allocated"
  if (.not. allocated(yc)) error stop "child allocated"
  select type (yb)
  type is (base)
    if (yb%n /= 4) error stop "base value"
  class default
    error stop "base dynamic type"
  end select
  select type (yc)
  type is (child)
    if (yc%m /= 6) error stop "child value"
  class default
    error stop "child dynamic type"
  end select
  if (dyn(b) /= 1) error stop "dyn base"
  if (dyn(c) /= 6) error stop "dyn child"
end program
