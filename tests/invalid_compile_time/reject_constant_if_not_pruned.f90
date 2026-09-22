! TEST-RULE: 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: IAND.*integer|arguments.*IAND|invalid.*real.*IAND
! TEST-ERROR-PHASE: compile
module reject_constant_if_not_pruned_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), intent(inout) :: x
    if (.false.) then
      ! TEST-ERROR-HERE
      x = iand(x, 1)
    end if
  end subroutine
end module
