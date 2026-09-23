! TEST-RULE: C1562 15.6.2.6 19.10.2
! TEST-DRAFT: generic-bind-c
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1562|binding label.*(match|differ|same|mismatch|interface body)|mismatch.*bind\(c\)|bind\(c\).*(name|label).*(mismatch|differ)
! TEST-ERROR-PHASE: compile
! A singleton generic separate module procedure has one explicit binding
! label, avoiding a duplicate label, but GENERIC plus BIND(C) remains the
! quarantined generic-bind-c reading. Under that reading, the definition's
! binding label has to equal the interface body's (C1562).
module integration_reject_separate_binding_label_mismatch_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
  interface
    module generic function stamp(x) result(y) bind(c, name="fgs_integration_stamp_interface")
      integer(c_int), value :: x
      integer(c_int) :: y
    end function
  end interface
end module
