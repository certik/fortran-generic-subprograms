! TEST-RULE: R504 R871 R1409 R1410 C1406 C1407 C1561 C8114 C8115 8.7 11.1.11.2 14.2.2 15.4.3.2 15.6.2.4
! TEST-PASS: audit-integration-default-kinds
! Bare REAL and COMPLEX in generic lists and guards denote the default kinds
! of their scoping unit (8.7): two textually identical families from modules
! with different default real kinds merge without ambiguity, and default
! complex follows default real. Module subprograms inherit the module's
! defaults; interface bodies, including MODULE GENERIC interface bodies,
! start from the standard defaults unless they change or import them. USE,
! DEFAULT_KINDS adopts a module's defaults in a nested subprogram and in an
! interface body. SINGLE_PRECISION and DOUBLE_PRECISION always denote two
! distinct real kinds (7.4.3.2), so no optional kind is required.
module audit_integration_default_kinds_standard_m
  implicit none
  private
  public :: classify
contains
  generic function classify(x) result(code)
    type(real, complex), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (real)
      code = 11
    declared type is (complex)
      code = 12
    end select
  end function
end module

module audit_integration_default_kinds_double_m
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  default kind (real = double_precision)
  implicit none
  private
  public :: classify, body_default, body_changed, apply_single

  interface
    module generic function body_default(x) result(y)
      real, intent(in) :: x
      real :: y
    end function

    module generic function body_changed(x) result(y)
      default kind (real = double_precision)
      real, intent(in) :: x
      real :: y
    end function
  end interface
contains
  generic function classify(x) result(code)
    type(real, complex), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (real)
      code = 21
    declared type is (complex)
      code = 22
    end select
  end function

  module generic function body_default(x) result(y)
    real(single_precision), intent(in) :: x
    real(single_precision) :: y
    y = 2*x
  end function

  module generic function body_changed(x) result(y)
    real, intent(in) :: x
    real :: y
    y = 3*x
  end function

  generic function apply_single(f, x) result(y)
    type(real, complex), intent(in) :: x
    interface
      function f(a) result(b)
        real, intent(in) :: a
        real :: b
      end function
    end interface
    typeof(x) :: y
    y = x + f(1.5_single_precision)
  end function
end module

module audit_integration_default_kinds_client_m
  implicit none
  private
  public :: client_codes, imported_body
contains
  function client_codes() result(codes)
    use, non_intrinsic, default_kinds :: audit_integration_default_kinds_double_m, only: classify
    use audit_integration_default_kinds_standard_m, only: classify
    use, intrinsic :: iso_fortran_env, only: single_precision
    integer :: codes(4)
    codes = [classify(1.0), classify((1.0, 2.0)), classify(1.0_single_precision), &
             classify((1.0_single_precision, 0.0_single_precision))]
  end function

  generic function imported_body(f, x) result(y)
    use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
    real([single_precision, double_precision]), intent(in) :: x
    interface
      function f(a) result(b)
        use, default_kinds :: audit_integration_default_kinds_double_m, only:
        real, intent(in) :: a
        real :: b
      end function
    end interface
    typeof(x) :: y
    y = x + f(0.5_double_precision)
  end function
end module

program audit_integration_default_kinds_p
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  use audit_integration_default_kinds_standard_m, only: classify
  use audit_integration_default_kinds_double_m, only: classify, body_default, &
    body_changed, apply_single
  use audit_integration_default_kinds_client_m, only: client_codes, imported_body
  implicit none
  complex(double_precision) :: z
  integer :: codes(4)

  if (classify(1.0) /= 11) error stop "standard default real family"
  if (classify((1.0, 2.0)) /= 12) error stop "standard default complex family"
  if (classify(1.0_single_precision) /= 11) error stop "single precision literal"
  if (classify(1.0_double_precision) /= 21) error stop "double-default real family"
  if (classify((1.0_double_precision, 2.0_double_precision)) /= 22) then
    error stop "default complex follows default real"
  end if

  if (body_default(1.5_single_precision) /= 3.0_single_precision) then
    error stop "interface body reset to standard default real"
  end if
  if (body_changed(1.5_double_precision) /= 4.5_double_precision) then
    error stop "interface body DEFAULT KIND statement"
  end if
  if (apply_single(halve, 1.0_double_precision) /= 1.75_double_precision) then
    error stop "dummy interface body uses standard default real"
  end if
  z = apply_single(halve, (1.0_double_precision, 2.0_double_precision))
  if (z /= (1.75_double_precision, 2.0_double_precision)) then
    error stop "complex specific with standard-default callback"
  end if

  codes = client_codes()
  if (any(codes /= [21, 22, 11, 12])) error stop "USE DEFAULT_KINDS in nested subprogram"
  if (imported_body(halve_double, 1.0_single_precision) /= 1.25_single_precision) then
    error stop "DEFAULT_KINDS interface body, single specific"
  end if
  if (imported_body(halve_double, 2.0_double_precision) /= 2.25_double_precision) then
    error stop "DEFAULT_KINDS interface body, double specific"
  end if
  print '(a)', 'TEST-PASS: audit-integration-default-kinds'
contains
  function halve(a) result(b)
    real, intent(in) :: a
    real :: b
    b = a/2
  end function

  function halve_double(a) result(b)
    real(double_precision), intent(in) :: a
    real(double_precision) :: b
    b = a/2
  end function
end program
