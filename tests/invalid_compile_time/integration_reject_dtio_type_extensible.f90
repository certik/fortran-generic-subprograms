! TEST-RULE: C1236 12.6.4.8.2 15.4.3.4.4 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: C1236|dtv.*(CLASS|extensible|polymorphic)|extensible.*(CLASS|polymorphic)|(defined|derived-type).*(input/output|I/O|WRITE).*(interface|characteristic|CLASS)|(WRITE|DTIO).*(dtv|CLASS)
! TEST-ERROR-PHASE: compile
! The SEQUENCE type is not extensible, so its generated specific correctly
! declares dtv with TYPE. OPEN_REC is extensible, so its generated specific
! would need CLASS (C1236) and lacks the WRITE(FORMATTED) interface; a
! family cannot contribute only its eligible specific (15.4.3.4.4).
! C1236 constrains the dtv-type-spec of the 12.6.4.8.2 interfaces; a
! procedure whose dtv differs from them violates the unnumbered 15.4.3.4.4
! requirement, so the diagnostic class is enhanced.
module integration_reject_dtio_type_extensible_m
  implicit none
  type :: sealed_rec
    sequence
    integer :: n = 0
  end type
  type :: open_rec
    integer :: n = 0
  end type
  interface write(formatted)
    ! TEST-ERROR-HERE
    procedure write_rec
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine write_rec(dtv, unit, iotype, v_list, iostat, iomsg)
    ! TEST-ERROR-HERE
    type(sealed_rec, open_rec), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    write(unit, '(i0)', iostat=iostat, iomsg=iomsg) dtv%n
  end subroutine
end module
