! TEST-RULE: 12.6.4.8.2 15.4.3.4.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: defined I/O.*(four|dummy|argument)|dummy arguments.*DTIO|DTIO.*arguments
! TEST-ERROR-PHASE: compile
module reject_defined_io_arity_m
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
  generic subroutine write_unformatted(dtv, unit, iostat)
    type(record_t), intent(in) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    iostat = 0
  end subroutine
end module
