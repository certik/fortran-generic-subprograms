! PROCEDURE of a generic name adds every specific to defined formatted
! output (15.4.3.4.1). Each specific has the WRITE(FORMATTED) interface.
! Extensible types use CLASS for the dtv argument (C1236).
module defined_io_m
  implicit none
  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type
  interface write(formatted)
    procedure write_item
  end interface
contains
  generic subroutine write_item(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    if (len(iotype) < 0 .or. size(v_list) < 0 .or. len(iomsg) < 0) then
      iostat = 1
      return
    end if
    write(unit, '(i0)') dtv%n
    iostat = 0
  end subroutine
end module

program defined_io_p
  use defined_io_m
  implicit none
  type(box) :: bx
  type(bag) :: bg
  character(len=40) :: line
  bx%n = 42
  bg%n = 17
  write(line, '(dt)') bx
  if (index(line, "42") == 0) error stop "box"
  write(line, '(dt)') bg
  if (index(line, "17") == 0) error stop "bag"
end program
