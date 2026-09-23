! TEST-RULE: C15107 15.6.2.1 15.6.2.4 15.7 15.9.1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15107|INTENT.OUT.*pure.*(final|impure)|final.*impure.*(pure|elemental)|impure.*final subroutine|elemental.*impure.*final
! TEST-ERROR-PHASE: compile
! ELEMENTAL without IMPURE makes every generated specific pure (15.6.2.1 p4).
! The calm_tracked specific is valid, but the noisy_tracked specific would
! finalize its INTENT(OUT) actual with an impure final subroutine.
module integration_reject_elemental_implicit_pure_final_m
  implicit none
  integer :: noisy_finals = 0
  type :: calm_tracked
    integer :: tag = 0
  contains
    final :: calm_final
  end type
  type :: noisy_tracked
    integer :: tag = 0
  contains
    final :: noisy_final
  end type
contains
  elemental subroutine calm_final(x)
    type(calm_tracked), intent(inout) :: x
    x%tag = 0
  end subroutine

  subroutine noisy_final(x)
    type(noisy_tracked), intent(inout) :: x
    noisy_finals = noisy_finals + 1
  end subroutine

  ! TEST-ERROR-HERE
  elemental generic subroutine elemental_reset(x, tag)
    ! TEST-ERROR-HERE
    type(calm_tracked, noisy_tracked), intent(out) :: x
    integer, intent(in) :: tag
    x%tag = tag
  end subroutine
end module
