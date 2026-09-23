! TEST-RULE: C1564 C1567 C1568 C1570 15.6.2.4 19.3.7 19.10.2
! TEST-DRAFT: generic-bind-c
! TEST-PASS: audit-integration-bind-c-abi
! A companion C source calls the explicit label of the singleton specific.
module audit_integration_bind_c_abi_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
  private
  public :: call_count
  integer :: call_count = 0
contains
  generic function c_step(x) result(y) bind(c, name="fgs_audit_generic_step")
    integer(c_int), value, intent(in) :: x
    integer(c_int) :: y
    call_count = call_count + 1
    y = 3_c_int*x + 1_c_int
  end function
end module
