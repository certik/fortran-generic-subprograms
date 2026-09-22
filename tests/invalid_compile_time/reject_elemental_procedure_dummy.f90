! TEST-RULE: C15135
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15135|elemental.*dummy.*data object|procedure dummy.*elemental
! TEST-ERROR-PHASE: compile
module reject_elemental_procedure_dummy_m
  implicit none
  abstract interface
    subroutine callback()
    end subroutine
  end interface
contains
  elemental generic subroutine s(p)
    ! TEST-ERROR-HERE
    procedure(callback), intent(in) :: p
  end subroutine
end module
