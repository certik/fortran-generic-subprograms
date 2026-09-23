! TEST-RULE: 14.2.2 15.6.2.4 15.6.2.5
! TEST-REQUIRES: int32 int64 real32 real64
! TEST-PASS: save_per_specific
! SAVE state is distinct for every type/kind/rank specific. Module host
! state is shared, and aliases of one generic reach the same specific state.
module save_per_specific_m
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
  implicit none
  integer, save, private :: host_hits = 0
contains
  generic function hit(x) result(code)
    type(integer([int32, int64]), real([real32, real64])), &
      intent(in), rank(0:1) :: x
    integer :: code
    integer, save :: local_hits = 0
    local_hits = local_hits + 1
    host_hits = host_hits + 1
    code = 100*host_hits + local_hits
  end function

  integer function host_count()
    host_count = host_hits
  end function
end module

program save_per_specific_p
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
  use save_per_specific_m, only: hit, host_count
  use save_per_specific_m, only: hit_alias => hit
  implicit none
  if (hit(1_int32) /= 101) error stop "int32 scalar first"
  if (hit([1_int32]) /= 201) error stop "int32 rank1 first"
  if (hit(1_int64) /= 301) error stop "int64 scalar first"
  if (hit([1_int64]) /= 401) error stop "int64 rank1 first"
  if (hit(1.0_real32) /= 501) error stop "real32 scalar first"
  if (hit([1.0_real32]) /= 601) error stop "real32 rank1 first"
  if (hit(1.0_real64) /= 701) error stop "real64 scalar first"
  if (hit([1.0_real64]) /= 801) error stop "real64 rank1 first"
  if (hit_alias(2_int32) /= 902) error stop "alias shares int32 scalar"
  if (hit([2_int32]) /= 1002) error stop "int32 rank1 second"
  if (hit_alias([2.0_real64]) /= 1102) error stop "alias shares real64 rank1"
  if (host_count() /= 11) error stop "shared module host state"
  print '(a)', 'TEST-PASS: save_per_specific'
end program
