! TEST-RULE: C1511 15.4.3.2 15.4.3.3 15.4.3.4.1 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1511|procedure.*specified previously|already specified.*generic|already present.*interface|duplicate.*(generic|interface|operator)|already.*in.*(generic|interface|operator)
! TEST-ERROR-PHASE: compile
! The GENERIC statement already specifies both generated specifics of the
! generic function TWICE for .TWICE. (15.4.3.3 p3). The interface block's
! PROCEDURE statement specifies the same two specifics again
! (15.4.3.4.1 p2), which violates C1511. The operator generic-spec permits a
! generic-name in both statements (C1505, C1512). No named specific exists.
module reject_duplicate_procedure_insertion_m
  implicit none
  generic :: operator(.twice.) => twice
  interface operator(.twice.)
    ! TEST-ERROR-HERE
    procedure twice
  end interface
contains
  generic function twice(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function
end module
