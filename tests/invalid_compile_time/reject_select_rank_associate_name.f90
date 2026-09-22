! TEST-RULE: R1151
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: associate name|unexpected.*=>|SELECT GENERIC RANK.*syntax
! TEST-ERROR-PHASE: compile
module reject_select_rank_associate_name_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    ! TEST-ERROR-HERE
    select generic rank (associate_name => x)
    rank default
      continue
    end select
  end subroutine
end module
