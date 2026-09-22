! TEST-RULE: C715
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C715|CLASS.*extensible|enum type.*not extensible
! TEST-ERROR-PHASE: compile
module reject_class_enum_type_m
  implicit none
  type :: extensible_t
    integer :: value
  end type
  enum, bind(c) :: colour_t
    enumerator :: red, blue
  end enum
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    class(extensible_t, colour_t) :: x
  end subroutine
end module
