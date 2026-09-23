! TEST-RULE: C15104 7.5.2.3 15.6.2.4 15.7
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15104|polymorphic.*allocatable.*(result|pure).*pure type|declared type.*(is not|not) pure|pure function.*polymorphic.*result
! TEST-ERROR-PHASE: compile
! The CLASSOF result of the pure_left specific has a pure declared type,
! but the plain_right specific returns a polymorphic allocatable result
! whose declared type is not pure.
module integration_reject_pure_polymorphic_result_type_m
  implicit none
  type, pure :: pure_left
    integer :: id = 0
  end type
  type :: plain_right
    integer :: weight = 0
  end type
contains
  pure generic function pure_clone(x) result(y)
    class(pure_left, plain_right), intent(in) :: x
    ! TEST-ERROR-HERE
    classof(x), allocatable :: y
    allocate(y, source=x)
  end function
end module
