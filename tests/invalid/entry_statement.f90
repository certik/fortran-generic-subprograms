! Invalid: C1589. ENTRY is not allowed in a generic subprogram.
module entry_statement_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    entry e(x)
  end subroutine
end module
