! TEST-RULE: C1511 C1513 15.4.3.4.5 15.6.2.4 NOTE4
! Specifics from an interface and from several generic subprograms of the
! same name form one generic (15.6.2.4 NOTE 4). Ranks and types disambiguate.
module extend_generic_m
  implicit none
  interface set_to
    module procedure set_to_logical
  end interface
contains
  subroutine set_to_logical(x)
    logical, intent(inout) :: x
    x = .not. x
  end subroutine

  generic subroutine set_to(x)
    integer, intent(out), rank(0) :: x
    x = 1
  end subroutine

  generic subroutine set_to(x)
    integer, intent(out), rank(1:2) :: x
    x = 2
  end subroutine

  generic subroutine set_to(x)
    real, intent(out), rank(0:2) :: x
    x = 3.0
  end subroutine
end module

program extend_generic_p
  use extend_generic_m
  implicit none
  logical :: flag
  integer :: n, v(2), m(2, 2)
  real :: r, rv(2), rm(1, 1)
  flag = .false.
  n = -1
  v = -1
  m = -1
  r = -1.0
  rv = -1.0
  rm = -1.0
  call set_to(flag)
  if (.not. flag) error stop "logical"
  call set_to(n)
  if (n /= 1) error stop "integer scalar"
  call set_to(v)
  if (any(v /= 2)) error stop "integer rank1"
  call set_to(m)
  if (any(m /= 2)) error stop "integer rank2"
  call set_to(r)
  if (r /= 3.0) error stop "real scalar"
  call set_to(rv)
  if (any(rv /= 3.0)) error stop "real rank1"
  call set_to(rm)
  if (any(rm /= 3.0)) error stop "real rank2"
end program
