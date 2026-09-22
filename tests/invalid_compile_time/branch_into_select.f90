! Invalid: 11.1.10.2. A branch to END SELECT is allowed only from inside
! the construct. This is not a numbered constraint; the suite still rejects it.
module branch_into_select_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    go to 100
    gr: select generic rank (x)
    rank (0) gr
      x = 0
    rank (1) gr
      x = 1
    100 end select gr
  end subroutine
end module
