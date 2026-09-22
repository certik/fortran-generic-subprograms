! TEST-RULE: 12.6.4.8.2 15.4.3.4.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined I/O.*INTENT|DTIO.*INTENT|dtv.*INTENT.IN|WRITE.*interface
! TEST-ERROR-PHASE: compile
module reject_defined_io_intent_m
  implicit none
  type :: record_t
    sequence
    integer :: value
  end type
  interface write(unformatted)
    ! TEST-ERROR-HERE
    procedure write_unformatted
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine write_unformatted(dtv, unit, iostat, iomsg)
    ! TEST-ERROR-HERE
    type(record_t), intent(inout) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    iostat = 0
  end subroutine
end module
