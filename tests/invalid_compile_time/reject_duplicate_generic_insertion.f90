! TEST-RULE: C1513 15.4.3.3 15.4.3.4.1 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1513|procedure.*specified previously|duplicate.*generic|already.*(specified|present|in).*(generic|interface|operator)
! TEST-ERROR-PHASE: compile
! The interface block's PROCEDURE statement already specifies both generated
! specifics of the generic function TWICE for .TWICE. (15.4.3.4.1 p2). The
! GENERIC statement's generic-name TWICE specifies the same two specifics
! again (15.4.3.3 p3), which violates C1513. The operator generic-spec permits
! a generic-name in both statements (C1505, C1512). No named specific exists.
module reject_duplicate_generic_insertion_m
  implicit none
  interface operator(.twice.)
    procedure twice
  end interface
  ! TEST-ERROR-HERE
  generic :: operator(.twice.) => twice
contains
  generic function twice(x) result(y)
    type(integer, real), intent(in) :: x
    typeof(x) :: y
    y = x + x
  end function
end module
