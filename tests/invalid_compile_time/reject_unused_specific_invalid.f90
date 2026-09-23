! TEST-RULE: 15.6.2.4p2 15.5.5.4 17.9.109
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: IAND.*(integer|int\b|expects)|arguments.*IAND|invalid.*real.*IAND|actual argument.*(bad|wrong|invalid) type
! TEST-ERROR-PHASE: compile
! The unused real specific references intrinsic IAND (15.5.5.4 p2) with a
! real I, which shall be integer or a boz-literal-constant (17.9.109). The
! program calls only the integer specific.
! Enhanced is a conservative classification, not a claim that 4.2 p2(7)
! cannot apply; see "Intrinsic-signature diagnostic policy" in
! doc/auto-generic-subprograms.md.
module reject_unused_specific_invalid_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), intent(inout) :: x
    ! TEST-ERROR-HERE
    x = iand(x, 1)
  end subroutine
end module

program reject_unused_specific_invalid_p
  use reject_unused_specific_invalid_m
  implicit none
  integer :: value
  call s(value)
end program
