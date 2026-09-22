! TEST-RULE: C1564
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1564|GENERIC.*MODULE|interface body.*GENERIC
! TEST-ERROR-PHASE: compile
! Invalid: C1564. An interface body may have GENERIC only together with MODULE.
module interface_body_m
  implicit none
  interface
    ! TEST-ERROR-HERE
    generic subroutine s(x)
      integer :: x
    end subroutine
  end interface
end module
