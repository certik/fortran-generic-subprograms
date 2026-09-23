! TEST-RULE: R705 R706 C704 C715 R771 R776 R777 R783 R1157 7.5.2.4 7.5.7
! TEST-PASS: language_type_domains
! One TYPE list mixes intrinsic, derived, interoperable enum, and enumeration
! types. Separate coverage passes SEQUENCE and BIND(C) types through TYPE.
! An abstract extensible type appears through CLASS but never in a
! DECLARED TYPE IS guard, where C704 would forbid it.
module language_type_domains_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
  type :: record
    integer :: value
  end type
  enum, bind(c) :: signal
    enumerator :: off = 0, on = 1
  end enum
  enumeration type :: season
    enumerator :: spring, summer
  end enumeration type
  type :: sequence_item
    sequence
    integer :: value
  end type
  type, bind(c) :: c_item
    integer(c_int) :: value
  end type
  type, abstract :: root
    integer :: value
  end type
  type, extends(root) :: leaf
    integer :: extra
  end type
  type :: other_base
    integer :: value
  end type
contains
  generic function mixed_code(x) result(n)
    type(integer(kind(off)), record, signal, season), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer(kind(off)))
      n = 100 + x
    declared type is (record)
      n = 200 + x%value
    declared type is (signal)
      if (x == signal(on)) then
        n = 301
      else
        n = 300
      end if
    declared type is (season)
      if (x == summer) then
        n = 402
      else
        n = 401
      end if
    end select
  end function

  generic function layout_code(x) result(n)
    type(sequence_item, c_item), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (sequence_item)
      n = 500 + x%value
    declared type is (c_item)
      n = 600 + int(x%value)
    end select
  end function

  generic function class_code(x) result(n)
    class(root, other_base), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (other_base)
      n = 700 + x%value
    declared type default
      select type (x)
      type is (leaf)
        n = 800 + x%value + x%extra
      class is (root)
        n = 900 + x%value
      end select
    end select
  end function
end module

program language_type_domains_p
  use language_type_domains_m
  implicit none
  type(record) :: r
  type(sequence_item) :: s
  type(c_item) :: c
  type(other_base) :: o
  class(root), allocatable :: p
  integer(kind(off)) :: ordinary_integer

  r%value = 7
  s%value = 8
  c%value = 9_c_int
  o%value = 10
  ordinary_integer = 5
  allocate(leaf :: p)
  select type (p)
  type is (leaf)
    p%value = 11
    p%extra = 12
  class default
    error stop "leaf allocation"
  end select

  if (mixed_code(ordinary_integer) /= 105) error stop "mixed integer"
  if (mixed_code(r) /= 207) error stop "mixed derived"
  if (mixed_code(signal(on)) /= 301) error stop "enum constructor"
  if (mixed_code(signal(off)) /= 300) error stop "enum constructor off"
  if (mixed_code(spring) /= 401) error stop "enumeration enumerator"
  if (mixed_code(season(2)) /= 402) error stop "enumeration constructor"
  if (layout_code(s) /= 508) error stop "sequence type"
  if (layout_code(c) /= 609) error stop "bind c type"
  if (class_code(o) /= 710) error stop "concrete class declared type"
  if (class_code(p) /= 823) error stop "abstract declared, leaf dynamic"
  print '(a)', 'TEST-PASS: language_type_domains'
end program
