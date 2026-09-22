! Invalid: C1158. END SELECT has a construct name and SELECT does not.
module construct_end_name_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    select generic rank (x)
    rank (0)
      x = 0
    rank (1)
      x = 1
    end select gr
  end subroutine
end module
