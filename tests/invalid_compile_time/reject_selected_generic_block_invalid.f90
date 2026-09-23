! TEST-RULE: 15.6.2.4p2 11.1.11.2 15.5.5.4 17.9.215
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: SQRT.*(real|complex|expects)|invalid.*integer.*SQRT|arguments.*SQRT|actual argument.*(bad|wrong|invalid) type
! TEST-ERROR-PHASE: compile
! The integer specific keeps its selected DECLARED TYPE IS (INTEGER) block
! (11.1.11.2), which references intrinsic SQRT (15.5.5.4 p2) with an integer
! argument; X shall be real or complex (17.9.215). The program calls only the
! real specific.
! Enhanced is a conservative classification, not a claim that 4.2 p2(7)
! cannot apply; see "Intrinsic-signature diagnostic policy" in
! doc/auto-generic-subprograms.md.
module reject_selected_generic_block_invalid_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real), intent(inout) :: x
    select generic type (x)
    declared type is (integer)
      ! TEST-ERROR-HERE
      x = sqrt(x)
    declared type is (real)
      x = sqrt(x)
    end select
  end subroutine
end module

program reject_selected_generic_block_invalid_p
  use reject_selected_generic_block_invalid_m
  implicit none
  real :: value
  call s(value)
end program
