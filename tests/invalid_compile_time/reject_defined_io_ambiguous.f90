! TEST-RULE: C1516 12.6.4.8.2 15.4.3.2 15.4.3.4.1 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1516|not distinguishable|ambiguous.*defined.*I/O|ambiguous interfaces.*_dtio|ambiguous.*generic
! TEST-ERROR-PHASE: compile
! PROCEDURE statements add every generated specific of two generic
! subroutines to WRITE(FORMATTED) (15.4.3.4.1 p2). REC_A, REC_B, and REC_C
! are unrelated extensible types, so each family is valid alone. Both
! families generate a CLASS(REC_B) specific, and those dtv arguments are not
! distinguishable, which violates C1516. No named specific is involved.
module reject_defined_io_ambiguous_m
  implicit none
  type :: rec_a
    integer :: value = 1
  end type
  type :: rec_b
    integer :: value = 2
  end type
  type :: rec_c
    integer :: value = 3
  end type
  ! TEST-ERROR-HERE
  interface write(formatted)
    ! TEST-ERROR-HERE
    procedure write_ab
    ! TEST-ERROR-HERE
    procedure write_bc
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine write_ab(dtv, unit, iotype, v_list, iostat, iomsg)
    class(rec_a, rec_b), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    write(unit, '(i0)', iostat=iostat, iomsg=iomsg) dtv%value
  end subroutine

  ! TEST-ERROR-HERE
  generic subroutine write_bc(dtv, unit, iotype, v_list, iostat, iomsg)
    class(rec_b, rec_c), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    write(unit, '(i0)', iostat=iostat, iomsg=iomsg) dtv%value
  end subroutine
end module
