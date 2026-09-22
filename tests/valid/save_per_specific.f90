! Each specific is its own procedure. A SAVE local belongs to that
! specific, not to the generic family (15.6.2.4, 15.6.2.5).
module save_per_specific_m
  implicit none
contains
  generic function hit(x) result(n)
    type(integer, real), intent(in) :: x
    integer :: n
    integer, save :: k = 0
    k = k + 1
    n = k
    if (kind(x) <= 0) error stop "kind"
  end function
end module

program save_per_specific_p
  use save_per_specific_m
  implicit none
  if (hit(1) /= 1) error stop "integer first"
  if (hit(1) /= 2) error stop "integer second"
  if (hit(1.0) /= 1) error stop "real has its own save"
  if (hit(1.0) /= 2) error stop "real second"
  if (hit(1) /= 3) error stop "integer third"
end program
