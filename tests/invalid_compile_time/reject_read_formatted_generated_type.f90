! TEST-RULE: 12.6.4.8.2 15.4.3.4.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined.*READ.*FORMATTED|dtv.*derived type|defined I/O.*interface
! TEST-ERROR-PHASE: compile
module reject_read_formatted_generated_type_m
  implicit none
  type :: record_t
    sequence
    integer :: value
  end type
  interface read(formatted)
    ! TEST-ERROR-HERE
    procedure read_formatted
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine read_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    ! TEST-ERROR-HERE
    type(record_t, integer), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    iostat = 0
  end subroutine
end module
