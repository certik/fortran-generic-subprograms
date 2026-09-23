! TEST-RULE: R871 R1409 R1410 C1406 8.7 11.1.11.2 14.2.2 15.6.2.4 17.9.52
! TEST-REQUIRES: character_kinds>=2
! TEST-PASS: audit-integration-default-kinds-character
! A second character kind exists only on some processors, so this fixture is
! gated separately. In the module whose default character kind is
! ALT_CHARACTER, bare CHARACTER(LEN=*) in a generic list denotes that kind.
! The alternate scopes use no character literal with characters, because a
! nonsystem character set need not contain them; values are built with
! CHAR(0) and empty literals. No DECLARED TYPE IS guard names a character
! type, so the assumed-length-guards reading is not involved.
module audit_integration_default_kinds_character_kinds_m
  use, intrinsic :: iso_fortran_env, only: character_kinds, system_character
  implicit none
  integer, parameter :: alt_character = merge(character_kinds(1), character_kinds(2), &
    character_kinds(1) /= system_character)
end module

module audit_integration_default_kinds_character_standard_m
  implicit none
  private
  public :: text_code, standard_marker
  type :: standard_marker
    integer :: n = 0
  end type
contains
  generic function text_code(x) result(code)
    type(character(len=*), standard_marker), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (standard_marker)
      code = 1
    declared type default
      code = 10 + len(x)
    end select
  end function
end module

module audit_integration_default_kinds_character_alt_m
  use audit_integration_default_kinds_character_kinds_m, only: alt_character
  default kind (character = alt_character)
  implicit none
  private
  public :: text_code, alt_marker, alt_text
  type :: alt_marker
    integer :: n = 0
  end type
contains
  generic function text_code(x) result(code)
    type(character(len=*), alt_marker), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (alt_marker)
      code = 2
    declared type default
      code = 20 + len(x)
    end select
  end function

  function alt_text(n) result(s)
    integer, intent(in) :: n
    character(len=n) :: s
    s = repeat(char(0), n)
  end function
end module

module audit_integration_default_kinds_character_client_m
  implicit none
  private
  public :: client_codes
contains
  function client_codes() result(codes)
    use, default_kinds :: audit_integration_default_kinds_character_alt_m, only: text_code
    use audit_integration_default_kinds_character_standard_m, only: text_code
    use, intrinsic :: iso_fortran_env, only: system_character
    integer :: codes(3)
    codes = [text_code(''), text_code(system_character_'xy'), text_code(repeat(char(0), 3))]
  end function
end module

program audit_integration_default_kinds_character_p
  use audit_integration_default_kinds_character_kinds_m, only: alt_character
  use audit_integration_default_kinds_character_standard_m, only: text_code, standard_marker
  use audit_integration_default_kinds_character_alt_m, only: text_code, alt_marker, alt_text
  use audit_integration_default_kinds_character_client_m, only: client_codes
  implicit none
  if (text_code('abc') /= 13) error stop "system default character family"
  if (text_code('') /= 10) error stop "system empty literal"
  if (text_code(standard_marker()) /= 1) error stop "standard marker specific"
  if (text_code(alt_text(2)) /= 22) error stop "alternate default character result"
  if (text_code(alt_character_'') /= 20) error stop "alternate empty literal"
  if (text_code(repeat(char(0, kind=alt_character), 4)) /= 24) then
    error stop "alternate CHAR values"
  end if
  if (text_code(alt_marker()) /= 2) error stop "alternate marker specific"
  if (any(client_codes() /= [20, 12, 23])) error stop "USE DEFAULT_KINDS character defaults"
  print '(a)', 'TEST-PASS: audit-integration-default-kinds-character'
end program
