! TEST-RULE: C1236 C1561 C1564 12.6.4.8.2 15.4.3.2 15.4.3.4.1 15.4.3.4.3 15.4.3.4.4 15.6.2.6
! TEST-PASS: audit-integration-separate-io-singleton
! MODULE GENERIC interface bodies inside ASSIGNMENT(=) and all four
! defined-I/O interface blocks each contribute their single unnamed specific
! (15.4.3.4.1 p2); the bodies are defined in a separately compiled
! submodule. No interface body contains a generic type declaration, so the
! C801 generic-interface-declarations tension is not involved. The length-*
! character dummies spell KIND=KIND(''): a scalar kind has only the ordinary
! parse (C718), which keeps the bodies independent of the character parse
! readings while matching the default-kind 12.6.4.8.2 interfaces.
module audit_integration_separate_io_singleton_m
  implicit none
  private
  public :: box
  public :: assignment(=), write(formatted), read(formatted)
  public :: write(unformatted), read(unformatted)

  type :: box
    integer :: n = 0
  end type

  interface assignment(=)
    module generic subroutine assign_box(lhs, rhs)
      type(box), intent(inout) :: lhs
      integer, intent(in) :: rhs
    end subroutine
  end interface

  interface write(formatted)
    module generic subroutine write_box_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
      class(box), intent(in) :: dtv
      integer, intent(in) :: unit
      character(len=*, kind=kind('')), intent(in) :: iotype
      integer, intent(in) :: v_list(:)
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface

  interface read(formatted)
    module generic subroutine read_box_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
      class(box), intent(inout) :: dtv
      integer, intent(in) :: unit
      character(len=*, kind=kind('')), intent(in) :: iotype
      integer, intent(in) :: v_list(:)
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface

  interface write(unformatted)
    module generic subroutine write_box_unformatted(dtv, unit, iostat, iomsg)
      class(box), intent(in) :: dtv
      integer, intent(in) :: unit
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface

  interface read(unformatted)
    module generic subroutine read_box_unformatted(dtv, unit, iostat, iomsg)
      class(box), intent(inout) :: dtv
      integer, intent(in) :: unit
      integer, intent(out) :: iostat
      character(len=*, kind=kind('')), intent(inout) :: iomsg
    end subroutine
  end interface
end module
