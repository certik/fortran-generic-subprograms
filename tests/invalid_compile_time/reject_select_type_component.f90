! TEST-RULE: C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|selector.*dummy argument|component.*SELECT GENERIC TYPE
! TEST-ERROR-PHASE: compile
module reject_select_type_component_m
  implicit none
  type :: first_t
    integer :: value
  end type
  type :: second_t
    integer :: value
  end type
contains
  generic subroutine s(x)
    type(first_t, second_t), intent(in) :: x
    ! TEST-ERROR-HERE
    select generic type (x%value)
    declared type is (integer)
      continue
    end select
  end subroutine
end module
