! TEST-RULE: 12.6.4.8.2 15.4.3.4.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined.*WRITE.*FORMATTED|dtv.*derived type|defined I/O.*interface
! TEST-ERROR-PHASE: compile
module reject_write_formatted_generated_type_m
  implicit none
  type :: record_t
    sequence
    integer :: value
  end type
  interface write(formatted)
    ! TEST-ERROR-HERE
    procedure write_formatted
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine write_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    ! TEST-ERROR-HERE
    type(record_t, integer), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    iostat = 0
  end subroutine
end module
