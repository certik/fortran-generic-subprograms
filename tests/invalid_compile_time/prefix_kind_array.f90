! TEST-RULE: R1529 R708
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: function prefix.*kind|declaration type.*array|unexpected.*\[
! TEST-ERROR-PHASE: compile
! Invalid syntax. A prefix type is a declaration-type-spec. A generic kind
! array is not a kind-selector. Declare the result with TYPEOF in the body.
module prefix_kind_array_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic integer([kind(0)]) function f(x)
    integer([kind(0)]), intent(in) :: x
    f = x
  end function
end module
