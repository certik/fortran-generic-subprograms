! TEST-RULE: C15135
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15135|elemental.*dummy.*ALLOCATABLE|ALLOCATABLE.*elemental
! TEST-ERROR-PHASE: compile
! Invalid: C15135. An elemental dummy is not allocatable.
module elemental_allocatable_m
  implicit none
contains
  elemental generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, allocatable, intent(inout) :: x
    x = 1
  end subroutine
end module
