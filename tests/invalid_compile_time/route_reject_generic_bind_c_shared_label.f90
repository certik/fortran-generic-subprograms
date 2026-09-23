! TEST-RULE: 15.6.2.4 19.10.2 20.2
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: binding label.*(same|duplicate|unique|shared|more than one|multiple|generic|specific)|same global (name|identifier)|global identifier.*(same|duplicate|unique)|(multiple definition|duplicate symbol|already defined|redefinition).*fgs_generic_bind_c_shared_label|fgs_generic_bind_c_shared_label.*(already defined|redefin|duplicate|multiple)
! TEST-ERROR-PHASE: compile-or-link
! Invalid under every reading of GENERIC plus BIND(C). The explicit nonempty
! NAME= makes "fgs_generic_bind_c_shared_label" the binding label of both
! generated specifics (19.10.2 p2), a scalar and a rank-one INTEGER(C_INT)
! dummy, each otherwise interoperable (C1568, C1570). A binding label is a
! global identifier, and 20.2 p2 forbids two entities from having the same
! one; 4.2 p2(6) requires the capability to report Clause 20 scope-rule
! violations. A processor may report it while translating the module or while
! linking; the complete main program references both specifics, so a link
! failure is not a missing-main artifact.
module route_reject_generic_bind_c_shared_label_m
  use, intrinsic :: iso_c_binding, only: c_int
  implicit none
  integer :: observed_rank = -1
contains
  ! TEST-ERROR-HERE
  generic subroutine observe(x) &
      bind(c, name="fgs_generic_bind_c_shared_label")
    integer(c_int), intent(in), rank(0:1) :: x
    observed_rank = rank(x)
  end subroutine
end module

program route_reject_generic_bind_c_shared_label_p
  use, intrinsic :: iso_c_binding, only: c_int
  use route_reject_generic_bind_c_shared_label_m
  implicit none
  integer(c_int) :: scalar, vector(2)
  scalar = 1_c_int
  vector = [2_c_int, 3_c_int]
  call observe(scalar)
  if (observed_rank /= 0) error stop "shared-label scalar specific"
  call observe(vector)
  if (observed_rank /= 1) error stop "shared-label rank-one specific"
end program
