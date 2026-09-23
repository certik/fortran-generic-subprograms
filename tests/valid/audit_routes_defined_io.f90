! TEST-RULE: R1506 R1507 R1509 C1505 C1516 12.6.4.8 15.4.3.2 15.4.3.4.1 15.4.3.4.4 15.6.2.4
! TEST-PASS: audit_routes_defined_io
! PROCEDURE statements in all four defined-I/O interface blocks name generic
! subroutines, so each block receives every generated CLASS(BOX) and
! CLASS(BAG) specific (15.4.3.4.1 p2). valid/defined_io.f90 covers the GENERIC
! statement route. All eight generated specifics are used, and the families
! stay private while the defined-I/O generic identifiers are public.
module audit_routes_defined_io_m
  implicit none
  private
  public :: box, bag
  public :: write(formatted), read(formatted)
  public :: write(unformatted), read(unformatted)

  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type

  interface write(formatted)
    procedure put_text
  end interface
  interface read(formatted)
    procedure :: get_text
  end interface
  interface write(unformatted)
    procedure put_binary
  end interface
  interface read(unformatted)
    procedure :: get_binary
  end interface
contains
  generic function tag_of(dtv) result(tag)
    class(box, bag), intent(in) :: dtv
    character(len=1) :: tag
    select generic type (dtv)
    declared type is (box)
      tag = "B"
    declared type is (bag)
      tag = "G"
    end select
  end function

  generic subroutine put_text(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    if (iotype /= "DT" .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = "unexpected formatted write edit descriptor"
      return
    end if
    write(unit, '(a,1x,i0)', iostat=iostat, iomsg=iomsg) tag_of(dtv), dtv%n
  end subroutine

  generic subroutine get_text(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=1) :: tag
    if (iotype /= "DT" .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = "unexpected formatted read edit descriptor"
      return
    end if
    read(unit, *, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= tag_of(dtv)) then
      iostat = 1
      iomsg = "wrong formatted type tag"
    end if
  end subroutine

  generic subroutine put_binary(dtv, unit, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    write(unit, iostat=iostat, iomsg=iomsg) tag_of(dtv), dtv%n
  end subroutine

  generic subroutine get_binary(dtv, unit, iostat, iomsg)
    class(box, bag), intent(inout) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    character(len=1) :: tag
    read(unit, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= tag_of(dtv)) then
      iostat = 1
      iomsg = "wrong unformatted type tag"
    end if
  end subroutine
end module

program audit_routes_defined_io_p
  use audit_routes_defined_io_m
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
  print '(a)', 'TEST-PASS: audit_routes_defined_io'
end program
