! TEST-RULE: C15119 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15119|PRINT.*pure|pure.*output
! TEST-ERROR-PHASE: compile
module reject_pure_selected_specific_m
  implicit none
contains
  pure generic subroutine s(x)
    type(integer, real), intent(in) :: x
    select generic type (x)
    declared type is (integer)
      ! TEST-ERROR-HERE
      print *, x
    declared type is (real)
      continue
    end select
  end subroutine
end module
