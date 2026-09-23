! TEST-RULE: C1561 8.5.17 15.4.3.2 15.6.2.4 15.6.2.6
! TEST-DRAFT: generic-interface-declarations
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|characteristics.*(interface|separate|module procedure)|(mismatch|not compatible|distinct|differ).*(interface|module procedure|declaration)|(interface|declaration).*(does not match|mismatch|differ|not compatible)|rank.*(does not match|mismatch|differ)
! TEST-ERROR-PHASE: compile
! Interface and definition both expand to two specifics whose X ranks are
! 0 and 1, but the interface pairs RANK(Y) with RANK(X) while the definition
! pairs it with 1-RANK(X). Equal specific counts are not enough: the
! corresponding specifics have different characteristics (C1561). The
! interface body needs a generic declaration, hence the draft tag.
module integration_reject_separate_correlation_mismatch_m
  implicit none
  interface
    module generic subroutine pair(x, y)
      integer, intent(in), rank(0:1) :: x
      integer, intent(inout), rank(rank(x)) :: y
    end subroutine
  end interface
end module
