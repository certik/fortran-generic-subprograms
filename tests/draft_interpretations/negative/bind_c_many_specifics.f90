! TEST-RULE: 19.10.2
! TEST-DRAFT: generic-bind-c
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: binding label.*(specific|procedure)|BIND.*generic|multiple.*binding label
! TEST-ERROR-PHASE: compile
! Invalid. One binding label cannot name both the integer specific and
! the real specific.
module bind_c_many_specifics_m
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine s(x) bind(c)
    type(integer, real), intent(in), value :: x
  end subroutine
end module
