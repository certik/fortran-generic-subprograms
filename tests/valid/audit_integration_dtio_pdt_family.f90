! TEST-RULE: C722 C723 C1236 C1237 C1516 12.6.4.8.2 15.4.3.3 15.4.3.4.4 15.6.2.4
! TEST-PASS: audit-integration-dtio-pdt-family
! A kind-generic PDT dtv family is eligible for defined input/output: the
! extensible type uses CLASS (C1236), its length parameter is assumed
! (C1237), and the two generated dtv dummies differ in a kind parameter, so
! they are distinguishable (C1516). The kind parameter is a user-defined
! integer, not an intrinsic kind, and zero is one of its values. The
! ineligible forms are integration_reject_dtio_*.
module audit_integration_dtio_pdt_family_m
  implicit none
  private
  public :: rec, write(formatted), read(formatted)

  type :: rec(tag, n)
    integer, kind :: tag
    integer, len :: n
    integer :: values(n)
  end type

  generic :: write(formatted) => write_rec
  generic :: read(formatted) => read_rec
contains
  generic subroutine write_rec(dtv, unit, iotype, v_list, iostat, iomsg)
    class(rec(tag=[0, 5], n=*)), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    if (iotype /= 'DT' .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = 'unexpected formatted edit descriptor'
      return
    end if
    write(unit, '(i0,a,i0,*(1x,i0))', iostat=iostat, iomsg=iomsg) dtv%tag, '/', dtv%n, dtv%values
  end subroutine

  generic subroutine read_rec(dtv, unit, iotype, v_list, iostat, iomsg)
    class(rec(tag=[0, 5], n=*)), intent(inout) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    if (iotype /= 'DT' .or. size(v_list) /= 0) then
      iostat = 1
      iomsg = 'unexpected formatted edit descriptor'
      return
    end if
    read(unit, *, iostat=iostat, iomsg=iomsg) dtv%values
    if (iostat == 0) dtv%values = dtv%values + dtv%tag
  end subroutine
end module

program audit_integration_dtio_pdt_family_p
  use audit_integration_dtio_pdt_family_m
  implicit none
  type(rec(0, 3)) :: zero_tag
  type(rec(5, 2)) :: five_tag
  character(len=40) :: line

  zero_tag%values = [1, 2, 3]
  five_tag%values = [7, 8]
  write(line, '(dt)') zero_tag
  if (adjustl(line) /= '0/3 1 2 3') error stop "tag-zero specific output"
  write(line, '(dt)') five_tag
  if (adjustl(line) /= '5/2 7 8') error stop "tag-five specific output"
  line = '4 5 6'
  read(line, '(dt)') zero_tag
  if (any(zero_tag%values /= [4, 5, 6])) error stop "tag-zero specific input"
  line = '10 20'
  read(line, '(dt)') five_tag
  if (any(five_tag%values /= [15, 25])) error stop "tag-five specific input"
  print '(a)', 'TEST-PASS: audit-integration-dtio-pdt-family'
end program
