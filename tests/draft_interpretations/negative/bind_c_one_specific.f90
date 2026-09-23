! TEST-RULE: 15.6.2.4 19.10.2
! TEST-DRAFT: generic-bind-c
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: binding label.*(generic|specific|name)|BIND.*generic|generic.*BIND
! TEST-ERROR-PHASE: compile
! Implicit-label observation under the selected generic-bind-c reading only.
! INTEGER([C_INT]) is kind-generic with a one-kind set, so there is exactly
! one unnamed specific, and its scalar VALUE dummy has an interoperable kind
! (C1568, C1570). With no NAME=, 19.10.2 p2 derives the binding label from
! the name of the procedure, but the specific has no name and S is a generic
! identifier. The selected reading rejects the implicit label; the draft does
! not settle that outcome, and acceptance is not a failure outside that
! profile. Explicit singleton labels are observed separately.
module bind_c_one_specific_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine s(x) bind(c)
    integer([c_int]), intent(in), value :: x
  end subroutine
end module
