submodule (audit_integration_separate_io_routes_m) audit_integration_separate_io_routes_s
  implicit none
contains
  module generic subroutine assign_item(lhs, rhs)
    type(box, bag), intent(inout) :: lhs
    type(integer, real), intent(in) :: rhs
    select generic type (rhs)
    declared type is (integer)
      lhs%n = rhs
    declared type is (real)
      lhs%n = -nint(rhs)
    end select
    select generic type (lhs)
    declared type is (bag)
      lhs%n = lhs%n + 1000
    end select
  end subroutine

  module generic subroutine write_item_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*, kind=kind('')), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    character(len=3) :: tag
    select generic type (dtv)
    declared type is (box)
      tag = 'BOX'
    declared type is (bag)
      tag = 'BAG'
    end select
    if (iotype /= 'DT' .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = 'unexpected formatted edit descriptor'
      return
    end if
    write(unit, '(a,1x,i0)', iostat=iostat, iomsg=iomsg) tag, dtv%n
  end subroutine

  module generic subroutine read_item_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
    class(box, bag), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*, kind=kind('')), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    character(len=3) :: tag, expected
    select generic type (dtv)
    declared type is (box)
      expected = 'BOX'
    declared type is (bag)
      expected = 'BAG'
    end select
    if (iotype /= 'DT' .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = 'unexpected formatted edit descriptor'
      return
    end if
    read(unit, *, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= expected) then
      iostat = 1
      iomsg = 'wrong formatted tag'
    end if
  end subroutine

  module generic subroutine write_item_unformatted(dtv, unit, iostat, iomsg)
    class(box, bag), intent(in) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    integer :: tag
    select generic type (dtv)
    declared type is (box)
      tag = 1
    declared type is (bag)
      tag = 2
    end select
    write(unit, iostat=iostat, iomsg=iomsg) tag, dtv%n
  end subroutine

  module generic subroutine read_item_unformatted(dtv, unit, iostat, iomsg)
    class(box, bag), intent(inout) :: dtv
    integer, intent(in) :: unit
    integer, intent(out) :: iostat
    character(len=*, kind=kind('')), intent(inout) :: iomsg
    integer :: tag, expected
    select generic type (dtv)
    declared type is (box)
      expected = 1
    declared type is (bag)
      expected = 2
    end select
    read(unit, iostat=iostat, iomsg=iomsg) tag, dtv%n
    if (iostat == 0 .and. tag /= expected) then
      iostat = 1
      iomsg = 'wrong unformatted tag'
    end if
  end subroutine
end submodule
