! TEST-RULE: C798 C1518 C1537 C1034 15.4.3.4.1 15.5.2.10 15.6.2.4 19.2.3.6 20.3.1
! TEST-PASS: audit-integration-same-name-specific
! Extending a generic does not hide an existing specific of the same name.
! Specific-procedure contexts select that existing procedure, not the family.
module audit_integration_same_name_specific_m
  implicit none
  abstract interface
    integer function integer_unary(x)
      integer, intent(in) :: x
    end function
  end interface
  interface lift
    module procedure lift
  end interface
  type :: holder
  contains
    procedure, nopass :: specific => lift
  end type
contains
  integer function lift(x)
    integer, intent(in) :: x
    lift = x + 10
  end function

  generic function lift(x) result(y)
    real, intent(in) :: x
    real :: y
    y = x + 0.5
  end function
end module

program audit_integration_same_name_specific_p
  use, intrinsic :: iso_c_binding, only: c_funloc, c_f_procpointer
  use audit_integration_same_name_specific_m, only: lift, integer_unary, holder
  use audit_integration_same_name_specific_m, only: renamed_lift => lift
  implicit none
  procedure(lift), pointer :: by_name
  procedure(integer_unary), pointer :: by_interface, through_c
  type(holder) :: object

  if (lift(3) /= 13) error stop "existing integer specific"
  if (lift(2.0) /= 2.5) error stop "generated real specific"
  if (apply(lift, 4) /= 14) error stop "same-name actual procedure"
  if (apply(renamed_lift, 5) /= 15) error stop "renamed actual procedure"
  by_name => lift
  by_interface => renamed_lift
  if (.not. associated(by_name, by_interface)) error stop "specific identity under rename"
  if (by_name(6) /= 16) error stop "specific interface and pointer"
  call c_f_procpointer(c_funloc(renamed_lift), through_c)
  if (.not. associated(through_c, by_name)) error stop "noninteroperable C_FUNLOC identity"
  if (through_c(7) /= 17) error stop "C_FUNLOC round trip"
  if (object%specific(8) /= 18) error stop "same-name type-bound target"
  print '(a)', 'TEST-PASS: audit-integration-same-name-specific'
contains
  integer function apply(f, x) result(y)
    procedure(integer_unary) :: f
    integer, intent(in) :: x
    y = f(x)
  end function
end program
