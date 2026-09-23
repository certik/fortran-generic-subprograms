! TEST-RULE: 15.6.2.4 19.10.2 20.2
! TEST-DRAFT: generic-bind-c
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: binding label.*(specific|procedure|generic|same)|BIND.*generic|multiple.*binding label|same global (name|identifier)
! TEST-ERROR-PHASE: compile
! Implicit-label observation under the selected generic-bind-c reading only.
! The scalar and rank-one INTEGER(C_INT) specifics are each interoperable: the
! kind is C_INT (C1570) and the rank-one dummy is assumed-shape (C1568). With
! no NAME=, 19.10.2 p2 either derives no label for the unnamed specifics or,
! if the generic name S were used, gives both specifics the label "s" (20.2).
! The selected reading rejects the implicit label; the draft does not settle
! that outcome. The explicit nonempty label case is the settled negative
! invalid_compile_time/route_reject_generic_bind_c_shared_label.f90.
module bind_c_many_specifics_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
contains
  ! TEST-ERROR-HERE
  generic subroutine s(x) bind(c)
    integer(c_int), intent(in), rank(0:1) :: x
  end subroutine
end module
