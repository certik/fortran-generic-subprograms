! TEST-RULE: C15107 7.5.6.2 7.5.6.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15107|INTENT.OUT.*pure.*(final|impure)|final.*impure.*pure|impure.*final subroutine|pure.*impure.*final
! TEST-ERROR-PHASE: compile
! The rank-one specific finalizes its INTENT(OUT) actual with a pure final
! subroutine, but the retained rank-two specific would reference the impure
! rank-two final subroutine. Removing rank 2 from the set makes it valid
! (valid/audit_integration_rank_finalization.f90).
module integration_reject_pure_rank_final_impure_m
  implicit none
  integer :: noisy_finals = 0
  type :: quiet_tracked
    integer :: tag = 0
  contains
    final :: quiet_final_vector, noisy_final_matrix
  end type
contains
  pure subroutine quiet_final_vector(x)
    type(quiet_tracked), intent(inout) :: x(:)
    x%tag = -x%tag
  end subroutine

  subroutine noisy_final_matrix(x)
    type(quiet_tracked), intent(inout) :: x(:, :)
    noisy_finals = noisy_finals + 1
  end subroutine

  ! TEST-ERROR-HERE
  pure generic subroutine quiet_reset(x, tag)
    ! TEST-ERROR-HERE
    type(quiet_tracked), intent(out), rank(1:2) :: x
    integer, intent(in) :: tag
    x%tag = tag
  end subroutine
end module
