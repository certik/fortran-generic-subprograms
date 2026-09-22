! Invalid syntax. Kind sets are rank-one arrays. REAL(*) was rejected
! (25-156r1 alternative 1b) and is not a generic-intrinsic-type-spec.
module star_all_kinds_m
  implicit none
contains
  generic subroutine s(x)
    real(*) :: x
  end subroutine
end module
