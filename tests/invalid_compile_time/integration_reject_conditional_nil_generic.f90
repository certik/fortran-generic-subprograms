! TEST-RULE: C802 C1543 15.5.2.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1543|\.NIL\..*(optional|nonoptional|not optional)|(nonoptional|not optional).*\.NIL\.|NIL.*dummy.*optional
! TEST-ERROR-PHASE: compile
! A generic dummy is never optional (C802), so .NIL. cannot be a consequent
! of its conditional argument, even though the optional nongeneric WEIGHT
! could receive one.
module integration_reject_conditional_nil_generic_m
  implicit none
contains
  generic function describe(x, weight) result(code)
    type(integer, real), intent(in) :: x
    real, intent(in), optional :: weight
    integer :: code
    code = 1
    if (present(weight)) code = 2
  end function
end module

program integration_reject_conditional_nil_generic_p
  use integration_reject_conditional_nil_generic_m
  implicit none
  logical :: flag
  integer :: value
  flag = .true.
  value = 4
  ! TEST-ERROR-HERE
  if (describe((flag ? value : .nil.), (flag ? 1.0 : .nil.)) /= 2) error stop "unreachable"
end program
