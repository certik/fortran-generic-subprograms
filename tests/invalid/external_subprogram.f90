! Invalid: C1564, C1582. GENERIC is not allowed on an external subprogram.
generic subroutine external_subprogram_s(x)
  integer, intent(inout) :: x
  x = 1
end subroutine
