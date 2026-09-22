! LOGICAL(LOGICAL_KINDS): one specific per logical kind (7.3.2.2).
module logical_kinds_m
  use, intrinsic :: iso_fortran_env, only: logical_kinds
  implicit none
contains
  generic function lnot(x) result(y)
    logical(logical_kinds), intent(in) :: x
    typeof(x) :: y
    y = .not. x
  end function
end module

program logical_kinds_p
  use logical_kinds_m
  implicit none
  if (lnot(.true.) .neqv. .false.) error stop "not true"
  if (lnot(.false.) .neqv. .true.) error stop "not false"
  if (kind(lnot(.true.)) /= kind(.true.)) error stop "logical kind"
end program
