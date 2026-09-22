! Invalid syntax. 25-156r1 had RANKOF(x). 26-007r1 spells that RANK(RANK(x)).
module rankof_syntax_m
  implicit none
contains
  generic subroutine s(x, y)
    integer, rank(0:1) :: x
    integer, rankof(x) :: y
  end subroutine
end module
