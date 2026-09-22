! TEST-RULE: C715
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C715|CLASS.*extensible|BIND.*not extensible
! TEST-ERROR-PHASE: compile
module reject_class_later_bind_c_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
  type :: extensible_t
    integer :: value
  end type
  type, bind(c) :: interoperable_t
    integer(c_int) :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    class(extensible_t, interoperable_t) :: x
  end subroutine
end module
