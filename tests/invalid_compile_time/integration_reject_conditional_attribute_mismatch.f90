! TEST-RULE: C1548 15.5.2.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1548|conditional.*(ALLOCATABLE|allocatable|attribute)|consequent.*(ALLOCATABLE|allocatable|attribute)|(ALLOCATABLE|allocatable).*consequent
! TEST-ERROR-PHASE: compile
! The dummy is not allocatable, so a nongeneric reference could mix these
! consequents; in a generic reference C1548 requires all consequents to have
! the ALLOCATABLE attribute if any does.
module integration_reject_conditional_attribute_mismatch_m
  implicit none
contains
  generic function describe(x) result(code)
    type(integer, real), intent(in), rank(0:1) :: x
    integer :: code
    code = 10*rank(x)
  end function
end module

program integration_reject_conditional_attribute_mismatch_p
  use integration_reject_conditional_attribute_mismatch_m
  implicit none
  integer, allocatable :: held(:)
  integer :: plain(3)
  logical :: flag
  flag = .true.
  allocate(held(2))
  held = 1
  plain = 2
  ! TEST-ERROR-HERE
  if (describe((flag ? held : plain)) /= 10) error stop "unreachable"
end program
