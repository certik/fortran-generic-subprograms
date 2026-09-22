! TEST-RULE: C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|CLASSOF.*not.*type-generic|selector.*type-generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1159. CLASSOF(x) is not a generic dummy.
module select_on_classof_m
  implicit none
  type :: base
    integer :: n
  end type
  type :: other
    integer :: n
  end type
contains
  generic subroutine s(x)
    type(base, other) :: x
    classof(x), allocatable :: y
    ! TEST-ERROR-HERE
    select generic type (y)
    declared type is (base)
      allocate(y)
    end select
  end subroutine
end module
