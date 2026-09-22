! Nonconforming even though nothing calls it (15.6.2.4 NOTE 3).
! The mixed-kind specifics pass two different kinds to MOD.
module mod_requires_same_kind_m
  use, intrinsic :: iso_fortran_env, only: real32, real64
  implicit none
contains
  generic real function bad(x, y)
    intrinsic mod
    real([real32, real64]) :: x
    real([real32, real64]) :: y
    bad = mod(x, y)
  end function
end module
