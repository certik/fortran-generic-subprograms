! TEST-RULE: 15.6.2.4p2
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: SQRT.*(real|complex)|invalid.*integer.*SQRT|arguments.*SQRT
! TEST-ERROR-PHASE: compile
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
