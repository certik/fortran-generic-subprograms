! TEST-RULE: C1514 15.4.3.2 15.4.3.4.1 15.4.3.4.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1514|ambiguous.*operator|operator.*not distinguishable|not distinguishable|ambiguous.*generic
! TEST-ERROR-PHASE: compile
! PROCEDURE statements naming two generic functions add all of their
! generated specifics to .COMBINE. (15.4.3.4.1 p2); the operator generic-spec
! permits a generic-name there (C1505). Each family is valid under its own
! generic name. Under .COMBINE., the generated rank-one specific of each
! family has one indistinguishable dummy and a different result type, which
! violates C1514. No named specific is involved.
module reject_operator_ambiguous_m
  implicit none
  ! TEST-ERROR-HERE
  interface operator(.combine.)
    ! TEST-ERROR-HERE
    procedure combine_count
    ! TEST-ERROR-HERE
    procedure combine_scale
  end interface
contains
  ! TEST-ERROR-HERE
  generic function combine_count(x) result(y)
    integer, intent(in), rank(0:1) :: x
    integer :: y
    y = 1
  end function

  ! TEST-ERROR-HERE
  generic function combine_scale(x) result(y)
    integer, intent(in), rank(1:2) :: x
    real :: y
    y = 2.0
  end function
end module
