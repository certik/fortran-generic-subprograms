! TEST-RULE: C1237 12.6.4.8.2 15.4.3.4.4 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: C1237|dtv.*(length|assumed)|length type parameter.*(assumed|dtv)|assumed.*length.*(dtv|parameter)|(defined|derived-type).*(input/output|I/O|READ).*(interface|characteristic)
! TEST-ERROR-PHASE: compile
! C717 already forbids an explicit length in a generic type specifier, so
! the ineligible dtv is an ordinary declaration of a singleton GENERIC
! subroutine: its explicit length N=4 violates C1237 and the READ(FORMATTED)
! interface. An assumed length is eligible
! (valid/audit_integration_dtio_pdt_family.f90). A deferred length would require
! ALLOCATABLE or POINTER (C702), a second dtv mismatch, so no isolated
! deferred-length case exists. As for C1236, a mismatch with the C1237-
! constrained interface is an unnumbered 15.4.3.4.4 violation (enhanced).
module integration_reject_dtio_pdt_explicit_length_m
  implicit none
  type :: rec(n)
    integer, len :: n
    integer :: values(n)
  end type
  interface read(formatted)
    ! TEST-ERROR-HERE
    procedure read_rec
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine read_rec(dtv, unit, iotype, v_list, iostat, iomsg)
    ! TEST-ERROR-HERE
    class(rec(n=4)), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    read(unit, *, iostat=iostat, iomsg=iomsg) dtv%values
  end subroutine
end module
