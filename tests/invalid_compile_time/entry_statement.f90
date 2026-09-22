! TEST-RULE: C1589
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1589|ENTRY.*generic|generic.*ENTRY
! TEST-ERROR-PHASE: compile
! Invalid: C1589. ENTRY is not allowed in a generic subprogram.
module entry_statement_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    ! TEST-ERROR-HERE
    entry e(x)
  end subroutine
end module
