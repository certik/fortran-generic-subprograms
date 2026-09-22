! TEST-RULE: R1156
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: associate name|unexpected.*=>|SELECT GENERIC TYPE.*syntax
! TEST-ERROR-PHASE: compile
module reject_select_type_associate_name_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x
    ! TEST-ERROR-HERE
    select generic type (associate_name => x)
    declared type default
      continue
    end select
  end subroutine
end module
