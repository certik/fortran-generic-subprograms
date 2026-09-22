! TEST-RULE: C715
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C715|CLASS.*extensible|SEQUENCE.*not extensible
! TEST-ERROR-PHASE: compile
module reject_class_later_sequence_m
  implicit none
  type :: extensible_t
    integer :: value
  end type
  type :: sequence_t
    sequence
    integer :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    class(extensible_t, sequence_t) :: x
  end subroutine
end module
