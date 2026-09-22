program integration_module_interface_routes_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use integration_module_interface_routes_m
  implicit none
  if (routed(4_int32) /= 5_int32) error stop "named int32 route"
  if (routed(6_int64) /= 7_int64) error stop "named int64 route"
  if ((.rankcode. 8_int32) /= 8) error stop "operator scalar route"
  if ((.rankcode. 9_int64) /= 9) error stop "operator int64 scalar route"
  if ((.rankcode. [1_int32, 4_int32]) /= 105) then
    error stop "operator int32 rank-one route"
  end if
  if ((.rankcode. [2_int64, 3_int64]) /= 105) then
    error stop "operator int64 rank-one route"
  end if
end program
