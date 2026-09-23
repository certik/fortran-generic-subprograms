! TEST-RULE: R871 R1409 R1410 C1406 8.7 10.1.5.5 11.1.11.2 14.2.2 15.6.2.4
! TEST-REQUIRES: logical_kinds>=2
! TEST-PASS: audit-integration-default-kinds-logical
! A second logical kind exists only on some processors, so this fixture is
! gated separately from the portable real/complex scoping fixture. In the
! module whose default logical kind is ALT_LOGICAL, bare LOGICAL in a generic
! list and in a DECLARED TYPE IS guard, logical literals, and relational
! results all have that kind; USE, DEFAULT_KINDS imports it.
module audit_integration_default_kinds_logical_kinds_m
  use, intrinsic :: iso_fortran_env, only: logical_kinds, standard_logical
  implicit none
  integer, parameter :: alt_logical = merge(logical_kinds(1), logical_kinds(2), &
    logical_kinds(1) /= standard_logical)
end module

module audit_integration_default_kinds_logical_standard_m
  implicit none
  private
  public :: flag_code, standard_marker
  type :: standard_marker
    integer :: n = 0
  end type
contains
  generic function flag_code(x) result(code)
    type(logical, standard_marker), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (logical)
      code = merge(11, 10, x)
    declared type is (standard_marker)
      code = 1
    end select
  end function
end module

module audit_integration_default_kinds_logical_alt_m
  use, intrinsic :: iso_fortran_env, only: standard_logical
  use audit_integration_default_kinds_logical_kinds_m, only: alt_logical
  default kind (logical = alt_logical)
  implicit none
  private
  public :: flag_code, which_logical, alt_marker, alt_compare, alt_true
  type :: alt_marker
    integer :: n = 0
  end type
contains
  generic function flag_code(x) result(code)
    type(logical, alt_marker), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (logical)
      code = merge(21, 20, x)
    declared type is (alt_marker)
      code = 2
    end select
  end function

  generic function which_logical(x) result(code)
    logical([standard_logical, alt_logical]), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (logical)
      code = 2
    declared type is (logical(standard_logical))
      code = 1
    end select
    if (.not. x) code = -code
  end function

  integer function alt_compare(a, b) result(code)
    integer, intent(in) :: a, b
    code = flag_code(a == b)
  end function

  function alt_true() result(v)
    logical :: v
    v = .true.
  end function
end module

module audit_integration_default_kinds_logical_client_m
  implicit none
  private
  public :: client_codes
contains
  function client_codes() result(codes)
    use, default_kinds :: audit_integration_default_kinds_logical_alt_m, only: flag_code
    use audit_integration_default_kinds_logical_standard_m, only: flag_code
    use, intrinsic :: iso_fortran_env, only: standard_logical
    integer :: codes(4)
    codes = [flag_code(.true.), flag_code(.false.), flag_code(.true._standard_logical), &
             flag_code(3 > 2)]
  end function
end module

program audit_integration_default_kinds_logical_p
  use audit_integration_default_kinds_logical_kinds_m, only: alt_logical
  use audit_integration_default_kinds_logical_standard_m, only: flag_code, standard_marker
  use audit_integration_default_kinds_logical_alt_m, only: flag_code, which_logical, &
    alt_marker, alt_compare, alt_true
  use audit_integration_default_kinds_logical_client_m, only: client_codes
  implicit none
  if (flag_code(.true.) /= 11) error stop "standard default logical family"
  if (flag_code(1 > 2) /= 10) error stop "standard relational result"
  if (flag_code(standard_marker()) /= 1) error stop "standard marker specific"
  if (flag_code(.true._alt_logical) /= 21) error stop "alternate logical family"
  if (flag_code(.false._alt_logical) /= 20) error stop "alternate false literal"
  if (flag_code(alt_true()) /= 21) error stop "alternate default logical result"
  if (flag_code(alt_marker()) /= 2) error stop "alternate marker specific"
  if (which_logical(.true.) /= 1) error stop "standard-kind guard"
  if (which_logical(.false.) /= -1) error stop "standard-kind guard, false"
  if (which_logical(.true._alt_logical) /= 2) error stop "bare LOGICAL guard in alternate scope"
  if (which_logical(.false._alt_logical) /= -2) error stop "bare LOGICAL guard, false"
  if (alt_compare(3, 3) /= 21 .or. alt_compare(3, 4) /= 20) then
    error stop "alternate relational result"
  end if
  if (any(client_codes() /= [21, 20, 11, 21])) error stop "USE DEFAULT_KINDS logical defaults"
  print '(a)', 'TEST-PASS: audit-integration-default-kinds-logical'
end program
