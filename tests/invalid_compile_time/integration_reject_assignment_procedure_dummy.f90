! TEST-RULE: C1585 15.4.3.4.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: assignment.*(dummy procedure|procedure argument|data object)|(dummy procedure|procedure argument).*assignment|argument of defined assignment.*INTENT\(IN\)
! TEST-ERROR-PHASE: compile
! Defined assignment dummies are dummy data objects (15.4.3.4.3 p2). The
! explicit interface satisfies C1585, but every generated specific has a
! dummy procedure as its second argument.
module integration_reject_assignment_procedure_dummy_m
  implicit none
  type :: box
    integer :: n = 0
  end type
  type :: bag
    integer :: n = 0
  end type
  abstract interface
    function source_value() result(v)
      integer :: v
    end function
  end interface
  interface assignment(=)
    ! TEST-ERROR-HERE
    procedure put
  end interface
contains
  ! TEST-ERROR-HERE
  generic subroutine put(lhs, rhs)
    type(box, bag), intent(inout) :: lhs
    ! TEST-ERROR-HERE
    procedure(source_value) :: rhs
    lhs%n = rhs()
  end subroutine
end module
