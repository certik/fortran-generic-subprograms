! TEST-PASS: audit-language-identity-ordinary-control
! TEST-RULE: 7.5.2 15.6.2.5 17.9.20 20.5.5
! Ordinary manually specialized control for the local-type and live internal
! procedure-pointer oracles used by audit_language_specialization_identity.
module audit_language_identity_ordinary_control_m
  implicit none

  abstract interface
    integer function reader_interface()
    end function
  end interface

  class(*), allocatable, save :: canonical_token, real_token_reference
contains
  subroutine observe_integer(x, is_canonical, payload)
    integer, intent(in) :: x
    logical, intent(out) :: is_canonical
    integer, intent(out) :: payload
    type :: local_token
      integer :: value
    end type
    type(local_token) :: token

    token%value = x
    if (.not. allocated(canonical_token)) then
      allocate(canonical_token, source=token)
      is_canonical = .true.
    else
      is_canonical = same_type_as(token, canonical_token)
    end if
    payload = token%value
  end subroutine

  subroutine observe_real(x, is_canonical, payload)
    real, intent(in) :: x
    logical, intent(out) :: is_canonical
    integer, intent(out) :: payload
    type :: local_token
      integer :: value
    end type
    type(local_token) :: token

    token%value = nint(10.0*x)
    if (.not. allocated(real_token_reference)) then
      allocate(real_token_reference, source=token)
    else if (.not. same_type_as(token, real_token_reference)) then
      error stop "ordinary real local type changed"
    end if
    is_canonical = same_type_as(token, canonical_token)
    payload = token%value
  end subroutine

  recursive subroutine integer_host(x, level, parent_reader, ancestor_reader, observed, distinct)
    integer, intent(in) :: x, level
    procedure(reader_interface), optional :: parent_reader
    procedure(reader_interface), optional :: ancestor_reader
    integer, intent(inout) :: observed(6)
    logical, intent(inout) :: distinct(3)
    procedure(reader_interface), pointer :: mine

    mine => read_host
    if (.not. associated(mine, read_host)) error stop "ordinary integer identity"
    select case (level)
    case (0)
      if (present(parent_reader) .or. present(ancestor_reader)) error stop "ordinary root readers"
      observed(1) = read_host()
      call real_host(15.0, read_host, observed, distinct)
    case (2)
      if (.not. present(parent_reader) .or. .not. present(ancestor_reader)) then
        error stop "ordinary missing live readers"
      end if
      observed(4) = read_host()
      observed(5) = parent_reader()
      observed(6) = ancestor_reader()
      distinct(2) = .not. associated(mine, parent_reader)
      distinct(3) = .not. associated(mine, ancestor_reader)
    case default
      error stop "ordinary integer level"
    end select
  contains
    integer function read_host()
      read_host = x
    end function
  end subroutine

  subroutine real_host(x, parent_reader, observed, distinct)
    real, intent(in) :: x
    procedure(reader_interface) :: parent_reader
    integer, intent(inout) :: observed(6)
    logical, intent(inout) :: distinct(3)
    procedure(reader_interface), pointer :: mine

    mine => read_host
    if (.not. associated(mine, read_host)) error stop "ordinary real identity"
    observed(2) = read_host()
    observed(3) = parent_reader()
    distinct(1) = .not. associated(mine, parent_reader)
    call integer_host(9, 2, parent_reader=read_host, ancestor_reader=parent_reader, &
                      observed=observed, distinct=distinct)
  contains
    integer function read_host()
      read_host = int(x)
    end function
  end subroutine
end module

program audit_language_identity_ordinary_control_p
  use audit_language_identity_ordinary_control_m
  implicit none
  logical :: is_canonical, distinct(3)
  integer :: payload, observed(6)

  call observe_integer(4, is_canonical, payload)
  if (.not. is_canonical .or. payload /= 4) error stop "ordinary first type"
  call observe_integer(7, is_canonical, payload)
  if (.not. is_canonical .or. payload /= 7) error stop "ordinary repeated type"
  call observe_real(1.5, is_canonical, payload)
  if (is_canonical .or. payload /= 15) error stop "ordinary distinct local type"

  observed = -1
  distinct = .false.
  call integer_host(7, 0, observed=observed, distinct=distinct)
  if (any(observed /= [7, 15, 7, 9, 15, 7])) error stop "ordinary host capture"
  if (.not. all(distinct)) error stop "ordinary internal procedure identity"

  print '(a)', 'TEST-PASS: audit-language-identity-ordinary-control'
end program
