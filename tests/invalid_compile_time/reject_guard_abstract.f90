! TEST-RULE: C704
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C704|abstract type.*DECLARED TYPE|type guard.*abstract
! TEST-ERROR-PHASE: compile
module reject_guard_abstract_m
  implicit none
  type, abstract :: abstract_t
    integer :: value
  end type
  type :: concrete_t
    integer :: value
  end type
contains
  generic subroutine s(x)
    class(abstract_t, concrete_t) :: x
    select generic type (x)
    ! TEST-ERROR-HERE
    declared type is (abstract_t)
      continue
    end select
  end subroutine
end module
