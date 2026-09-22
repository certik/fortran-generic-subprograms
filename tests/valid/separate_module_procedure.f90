! TEST-RULE: C1561 C1564 15.4.3.2 15.4.3.4.1 15.6.2.6
! TEST-REQUIRES: int32 int64
! TEST-DRAFT: generic-interface-declarations
! MODULE GENERIC on the interface body and on the defining submodule
! procedure (15.4.3.2 p4, C1561, C1564).
module separate_module_procedure_m
  implicit none
  interface
    module generic function inc(n) result(r)
      use, intrinsic :: iso_fortran_env, only: integer_kinds
      integer(integer_kinds), intent(in) :: n
      typeof(n) :: r
    end function
  end interface
end module

submodule (separate_module_procedure_m) separate_module_procedure_s
  implicit none
contains
  module generic function inc(n) result(r)
    use, intrinsic :: iso_fortran_env, only: integer_kinds
    integer(integer_kinds), intent(in) :: n
    typeof(n) :: r
    r = n + 1
  end function
end submodule

program separate_module_procedure_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use separate_module_procedure_m
  implicit none
  if (inc(5) /= 6) error stop "default"
  if (inc(5_int32) /= 6_int32) error stop "int32"
  if (inc(5_int64) /= 6_int64) error stop "int64"
end program
