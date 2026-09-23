! TEST-RULE: R1509 R1510 C1512 C1516 12.6.4.8 15.4.3.3 15.4.3.4.4
! TEST-PASS: defined_io
! GENERIC statements attach all generated specifics to all four defined-I/O
! identifiers. The implementation names remain private.
module defined_io_m
  implicit none
  private
  public :: box, bag

  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type

  generic, public :: write(formatted) => write_item_formatted
  generic, public :: read(formatted) => read_item_formatted
  generic, public :: write(unformatted) => write_item_unformatted
  generic, public :: read(unformatted) => read_item_unformatted
contains
  generic subroutine write_item_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=1) :: tag
    select generic type (dtv)
    declared type is (box)
      tag = "B"
    declared type is (bag)
      tag = "G"
    end select
    if (len(iotype) == 0 .or. size(v_list) < 0) then
      iostat = 1
      iomsg = "invalid defined-I/O metadata"
      return
    end if
    write(unit, '(a,1x,i0)', iostat=iostat, iomsg=iomsg) tag, dtv%n
  end subroutine

  generic subroutine read_item_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=1) :: tag, expected
    select generic type (dtv)
    declared type is (box)
      expected = "B"
    declared type is (bag)
      expected = "G"
    end select
    if (len(iotype) == 0 .or. size(v_list) < 0) then
      iostat = 1
      iomsg = "invalid defined-I/O metadata"
      return
    end if
    read(unit, *, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= expected) then
      iostat = 1
      iomsg = "wrong formatted type tag"
    end if
  end subroutine

  generic subroutine write_item_unformatted(dtv, unit, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=1) :: tag
    select generic type (dtv)
    declared type is (box)
      tag = "B"
    declared type is (bag)
      tag = "G"
    end select
    write(unit, iostat=iostat, iomsg=iomsg) tag, dtv%n
  end subroutine

  generic subroutine read_item_unformatted(dtv, unit, iostat, iomsg)
    class(box, bag), intent(inout) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=1) :: tag, expected
    select generic type (dtv)
    declared type is (box)
      expected = "B"
    declared type is (bag)
      expected = "G"
    end select
    read(unit, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= expected) then
      iostat = 1
      iomsg = "wrong unformatted type tag"
    end if
  end subroutine
end module

program defined_io_p
  use defined_io_m
  implicit none
  type(box) :: bx, bx_read
  type(bag) :: bg, bg_read
  character(len=40) :: line
  integer :: unit

  bx%n = 42
  bg%n = 17
  write(line, '(dt)') bx
  if (index(line, "B 42") == 0) error stop "formatted box write"
  write(line, '(dt)') bg
  if (index(line, "G 17") == 0) error stop "formatted bag write"

  line = "B 91"
  read(line, '(dt)') bx_read
  if (bx_read%n /= 91) error stop "formatted box read"
  line = "G 73"
  read(line, '(dt)') bg_read
  if (bg_read%n /= 73) error stop "formatted bag read"

  open(newunit=unit, status="scratch", form="unformatted", action="readwrite")
  write(unit) bx
  write(unit) bg
  rewind(unit)
  read(unit) bx_read
  read(unit) bg_read
  close(unit)
  if (bx_read%n /= 42) error stop "unformatted box round trip"
  if (bg_read%n /= 17) error stop "unformatted bag round trip"
  print '(a)', 'TEST-PASS: defined_io'
end program
