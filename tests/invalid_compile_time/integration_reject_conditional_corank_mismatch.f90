! TEST-RULE: C1548 15.5.2.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1548|conditional.*(same|different|mismatch).*corank|consequent.*corank|corank.*consequent
! TEST-ERROR-PHASE: compile
! In a reference to a nongeneric procedure the mixed-corank conditional
! argument would simply have corank zero (15.5.2.3 p4); in this generic
! reference C1548 requires every consequent to have the same corank.
module integration_reject_conditional_corank_mismatch_m
  implicit none
contains
  generic function describe(x) result(code)
    type(integer, real), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (integer)
      code = 1
    declared type is (real)
      code = 2
    end select
  end function
end module

program integration_reject_conditional_corank_mismatch_p
  use integration_reject_conditional_corank_mismatch_m
  implicit none
  integer :: shared[*]
  integer :: local
  logical :: flag
  flag = .true.
  shared = 1
  local = 2
  ! TEST-ERROR-HERE
  if (describe((flag ? shared : local)) /= 1) error stop "unreachable"
end program
