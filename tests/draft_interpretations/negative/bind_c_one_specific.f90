! TEST-RULE: 19.10.2
! TEST-DRAFT: generic-bind-c
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: binding label.*(generic|specific)|BIND.*generic|generic.*BIND
! TEST-ERROR-PHASE: compile
! Invalid under the reading used by this suite. BIND(C) gives one binding
! label to one procedure. A generic subprogram's specifics are unnamed, and
! its name is a generic identifier, even when there is only one specific.
module bind_c_one_specific_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine s(x) bind(c)
    integer, intent(in), value :: x
  end subroutine
end module
