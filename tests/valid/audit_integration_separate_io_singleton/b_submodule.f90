submodule (audit_integration_separate_io_singleton_m) audit_integration_separate_io_singleton_s
  implicit none
contains
  module generic subroutine assign_box(lhs, rhs)
    type(box), intent(inout) :: lhs
    integer, intent(in) :: rhs
    lhs%n = 10*rhs
  end subroutine

  module generic subroutine write_box_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*, kind=kind('')), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    if (iotype /= 'DT' .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = 'unexpected formatted edit descriptor'
      return
    end if
    write(unit, '(a,1x,i0)', iostat=iostat, iomsg=iomsg) 'BOX', dtv%n
  end subroutine

  module generic subroutine read_box_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*, kind=kind('')), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    character(len=3) :: tag
    if (iotype /= 'DT' .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = 'unexpected formatted edit descriptor'
      return
    end if
    read(unit, *, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= 'BOX') then
      iostat = 1
      iomsg = 'wrong formatted tag'
    end if
  end subroutine

  module generic subroutine write_box_unformatted(dtv, unit, iostat, iomsg)
    class(box), intent(in) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    write(unit, iostat=iostat, iomsg=iomsg) -dtv%n
  end subroutine

  module generic subroutine read_box_unformatted(dtv, unit, iostat, iomsg)
    class(box), intent(inout) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    integer :: stored
    read(unit, iostat=iostat, iomsg=iomsg) stored
    if (iostat == 0) dtv%n = -stored
  end subroutine
end submodule
