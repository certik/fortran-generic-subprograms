! TEST-RULE: C1516
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1516|not distinguishable|ambiguous.*defined.*I/O|ambiguous interfaces.*_dtio
! TEST-ERROR-PHASE: compile
module reject_defined_io_ambiguous_m
  implicit none
  type :: record_t
    integer :: value
  end type
  ! TEST-ERROR-HERE
  interface write(formatted)
    module procedure write_one
    ! TEST-ERROR-HERE
    module procedure write_two
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine write_one(dtv, unit, iotype, v_list, iostat, iomsg)
    class(record_t), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    iostat = 0
  end subroutine

  ! TEST-ERROR-HERE
  subroutine write_two(dtv, unit, iotype, v_list, iostat, iomsg)
    class(record_t), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    iostat = 0
  end subroutine
end module
