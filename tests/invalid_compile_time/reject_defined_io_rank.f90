! TEST-RULE: 12.6.4.8.2 15.4.3.4.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined I/O.*dtv.*scalar|dtv.*rank|defined.*WRITE.*UNFORMATTED
! TEST-ERROR-PHASE: compile
module reject_defined_io_rank_m
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
    type(record_t), rank(0:1), intent(in) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    iostat = 0
  end subroutine
end module
