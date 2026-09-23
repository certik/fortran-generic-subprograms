! TEST-RULE: C801 C1236 C1515 C1516 C1561 C1564 12.6.4.8.2 15.4.3.2 15.4.3.4.1 15.4.3.4.3 15.4.3.4.4 15.6.2.6
! TEST-DRAFT: generic-interface-declarations
! TEST-PASS: audit-integration-separate-io-routes
! Expanding MODULE GENERIC interface bodies inside ASSIGNMENT(=) and all four
! defined-I/O interface blocks contribute every generated specific
! (15.4.3.4.1 p2): four assignment specifics and two of each defined-I/O
! kind, defined in a separately compiled submodule. The bodies need generic
! type declarations, which C801 does not list for interface bodies, so the
! case is quarantined; the settled singleton route is
! valid/audit_integration_separate_io_singleton/.
module audit_integration_separate_io_routes_m
  implicit none
  private
  public :: box, bag
  public :: assignment(=), write(formatted), read(formatted)
  public :: write(unformatted), read(unformatted)

  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type

  interface assignment(=)
    module generic subroutine assign_item(lhs, rhs)
      type(box, bag), intent(inout) :: lhs
      type(integer, real), intent(in) :: rhs
    end subroutine
  end interface

  interface write(formatted)
    module generic subroutine write_item_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
      class(box, bag), intent(in) :: dtv
      integer, intent(in) :: unit
      character(len=*, kind=kind('')), intent(in) :: iotype
      integer, intent(in) :: v_list(:)
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface

  interface read(formatted)
    module generic subroutine read_item_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
      class(box, bag), intent(inout) :: dtv
      integer, intent(in) :: unit
      character(len=*, kind=kind('')), intent(in) :: iotype
      integer, intent(in) :: v_list(:)
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface

  interface write(unformatted)
    module generic subroutine write_item_unformatted(dtv, unit, iostat, iomsg)
      class(box, bag), intent(in) :: dtv
      integer, intent(in) :: unit
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface

  interface read(unformatted)
    module generic subroutine read_item_unformatted(dtv, unit, iostat, iomsg)
      class(box, bag), intent(inout) :: dtv
      integer, intent(in) :: unit
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface
end module
