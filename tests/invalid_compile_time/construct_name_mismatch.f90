! Invalid: C1158. END SELECT must repeat the construct name.
module construct_name_mismatch_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    gr: select generic rank (x)
    rank (0) gr
      x = 0
    rank (1) gr
      x = 1
    end select other
  end subroutine
end module
