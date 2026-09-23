! TEST-RULE: C15135
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15135|elemental.*dummy procedure|dummy procedure.*elemental|elemental.*dummy.*(data object|pointer)
! TEST-ERROR-PHASE: compile
! Invalid only by C15135: each generated elemental specific has a dummy
! procedure pointer, which is not a scalar nonpointer dummy data object. The
! callback interface is pure (C15112), INTENT is on a dummy procedure pointer
! (C850), and every dummy argument has an intent (C15137).
module reject_elemental_procedure_dummy_m
  implicit none
  abstract interface
    pure subroutine callback()
    end subroutine
  end interface
contains
  ! TEST-ERROR-HERE
  elemental generic subroutine s(x, p)
    type(integer, real), intent(in) :: x
    ! TEST-ERROR-HERE
    procedure(callback), pointer, intent(in) :: p
  end subroutine
end module
