! TEST-RULE: C707 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C707|abstract type.*TYPE|nonpolymorphic.*abstract
! TEST-ERROR-PHASE: compile
module reject_type_abstract_m
  implicit none
  type, abstract :: abstract_t
    integer :: value
  end type
  type :: concrete_t
    integer :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(concrete_t, abstract_t) :: x
  end subroutine
end module
