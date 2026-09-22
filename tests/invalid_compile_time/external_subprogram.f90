! TEST-RULE: C1564 C1582
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1564|C1582|generic.*(module|internal)|external.*generic
! TEST-ERROR-PHASE: compile
! Invalid: C1564, C1582. GENERIC is not allowed on an external subprogram.
! TEST-ERROR-HERE
generic subroutine external_subprogram_s(x)
  integer, intent(inout) :: x
  x = 1
end subroutine
