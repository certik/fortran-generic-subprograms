! TEST-RULE: C1564 15.6.2.4 19.10.2
! TEST-DRAFT: generic-bind-c
! With no generic dummy there is one specific, so one explicit nonempty
! binding label is associated with exactly one interoperable procedure.
module integration_generic_bind_c_singleton_label_m
  implicit none
  private
  public :: mark_call, call_count
  integer :: call_count = 0
contains
  generic subroutine mark_call() &
      bind(c, name="fgs_generic_bind_c_singleton")
    call_count = call_count + 1
  end subroutine
end module

program integration_generic_bind_c_singleton_label_p
  use integration_generic_bind_c_singleton_label_m
  implicit none
  call mark_call()
  call mark_call()
  if (call_count /= 2) error stop "singleton binding-label call"
end program
