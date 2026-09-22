! TEST-RULE: 7.5.6 9.7.1 15.5.2.13 15.6.2.4
! Generated specifics finalize INTENT(OUT) actuals independently. A
! rank-generic polymorphic allocatable is source-allocated and reallocated.
module integration_finalization_polymorphism_m
  implicit none
  integer, private :: box_finalizations = 0
  integer, private :: bag_finalizations = 0

  type :: box
    integer, allocatable :: data(:)
  contains
    final :: finalize_box
  end type

  type :: bag
    integer, allocatable :: data(:)
  contains
    final :: finalize_bag
  end type

  type :: base
    integer :: tag = 0
  end type

  type, extends(base) :: child
    integer :: extra = 0
  end type
contains
  subroutine finalize_box(x)
    type(box), intent(inout) :: x
    box_finalizations = box_finalizations + 1
  end subroutine

  subroutine finalize_bag(x)
    type(bag), intent(inout) :: x
    bag_finalizations = bag_finalizations + 1
  end subroutine

  generic subroutine replace_payload(x, n)
    type(box, bag), intent(out) :: x
    integer, intent(in) :: n
    integer :: i
    allocate(x%data(n))
    x%data = [(i, i=1, n)]
  end subroutine

  generic subroutine allocate_dynamic(x, want_child)
    class(base), allocatable, intent(out), rank(0:1) :: x
    logical, intent(in) :: want_child
    select generic rank (x)
    rank (0)
      if (want_child) then
        allocate(x, source=child(7, 70))
      else
        allocate(x, source=base(3))
      end if
    rank (1)
      if (want_child) then
        allocate(x, source=[child(8, 80), child(9, 90)])
      else
        allocate(x, source=[base(4), base(5)])
      end if
    end select
  end subroutine

  subroutine finalization_counts(box_count, bag_count)
    integer, intent(out) :: box_count, bag_count
    box_count = box_finalizations
    bag_count = bag_finalizations
  end subroutine
end module

program integration_finalization_polymorphism_p
  use integration_finalization_polymorphism_m
  implicit none
  type(box) :: bx
  type(bag) :: bg
  class(base), allocatable :: scalar
  class(base), allocatable :: vector(:)
  integer :: box_count, bag_count

  allocate(bx%data, source=[9, 8])
  allocate(bg%data, source=[7, 6, 5])
  call replace_payload(bx, 3)
  call finalization_counts(box_count, bag_count)
  if (box_count /= 1 .or. bag_count /= 0) error stop "box finalization"
  if (any(bx%data /= [1, 2, 3])) error stop "box replacement"
  call replace_payload(bg, 2)
  call finalization_counts(box_count, bag_count)
  if (box_count /= 1 .or. bag_count /= 1) error stop "bag finalization"
  if (any(bg%data /= [1, 2])) error stop "bag replacement"

  call allocate_dynamic(scalar, .true.)
  select type (scalar)
  type is (child)
    if (scalar%tag /= 7 .or. scalar%extra /= 70) error stop "scalar child data"
  class default
    error stop "scalar child dynamic type"
  end select
  call allocate_dynamic(scalar, .false.)
  select type (scalar)
  type is (base)
    if (scalar%tag /= 3) error stop "scalar base data"
  class default
    error stop "scalar reallocation dynamic type"
  end select

  call allocate_dynamic(vector, .true.)
  if (any(shape(vector) /= [2])) error stop "polymorphic vector shape"
  select type (vector)
  type is (child)
    if (any(vector%tag /= [8, 9])) error stop "vector child tags"
    if (any(vector%extra /= [80, 90])) error stop "vector child data"
  class default
    error stop "vector child dynamic type"
  end select
  call allocate_dynamic(vector, .false.)
  if (any(shape(vector) /= [2])) error stop "reallocated base vector shape"
  select type (vector)
  type is (base)
    if (any(vector%tag /= [4, 5])) error stop "vector base data"
  class default
    error stop "vector reallocation dynamic type"
  end select
end program
