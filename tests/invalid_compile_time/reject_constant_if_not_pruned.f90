! TEST-RULE: 15.6.2.4p2 15.5.5.4 17.9.109
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: IAND.*(integer|int\b|expects)|arguments.*IAND|invalid.*real.*IAND|actual argument.*(bad|wrong|invalid) type
! TEST-ERROR-PHASE: compile
! A constant-false ordinary IF is not pruned, so the real specific keeps
! the reference to intrinsic IAND (15.5.5.4 p2), whose I shall be integer or
! a boz-literal-constant (17.9.109).
! Enhanced is a conservative classification, not a claim that 4.2 p2(7)
! cannot apply; see "Intrinsic-signature diagnostic policy" in
! doc/auto-generic-subprograms.md.
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
