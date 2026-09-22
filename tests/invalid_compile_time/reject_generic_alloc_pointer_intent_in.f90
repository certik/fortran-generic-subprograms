! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|not distinguishable|ALLOCATABLE.*POINTER.*INTENT.IN|ambiguous.*generic
! TEST-ERROR-PHASE: compile
module reject_generic_alloc_pointer_intent_in_m
  implicit none
  ! TEST-ERROR-HERE
  interface consume
    module procedure consume_allocatable
    ! TEST-ERROR-HERE
    module procedure consume_pointer
  end interface
contains
  ! TEST-ERROR-HERE
  subroutine consume_allocatable(x)
    integer, allocatable, intent(in) :: x
  end subroutine

  ! TEST-ERROR-HERE
  subroutine consume_pointer(x)
    integer, pointer, intent(in) :: x
  end subroutine
end module
