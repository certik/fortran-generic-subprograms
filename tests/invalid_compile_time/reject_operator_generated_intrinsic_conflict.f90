! TEST-RULE: 15.4.3.4.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: intrinsic operator.*conflict|operator.*intrinsic.*same|cannot redefine.*\\+
! TEST-ERROR-PHASE: compile
module reject_operator_generated_intrinsic_conflict_m
  implicit none
  type :: box_t
    integer :: value
  end type
  interface operator(+)
    ! TEST-ERROR-HERE
    procedure add
  end interface
contains
  ! TEST-ERROR-HERE
  generic function add(a, b) result(c)
    type(integer, box_t), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a
  end function
end module
