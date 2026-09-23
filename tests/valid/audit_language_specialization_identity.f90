! TEST-PASS: audit-language-specialization-identity
! TEST-RULE: 15.6.2.4p2 15.6.2.4NOTE1 15.6.2.5 17.9.20 20.5.5
! Identical non-SEQUENCE local type definitions belong to distinct generated
! specific scopes.  Internal procedure pointers are compared and invoked only
! while every captured host instance remains active.
module audit_language_specialization_identity_m
  implicit none

  abstract interface
    integer function reader_interface()
    end function
  end interface

  class(*), allocatable, save :: canonical_token, real_token_reference
contains
  generic subroutine observe_local_type(x, is_canonical, payload)
    type(integer, real), intent(in) :: x
    logical, intent(out) :: is_canonical
    integer, intent(out) :: payload
    type :: local_token
      integer :: value
    end type
    type(local_token) :: token

    select generic type (x)
    declared type is (integer)
      token%value = x
    declared type is (real)
      token%value = nint(10.0*x)
      if (.not. allocated(real_token_reference)) then
        allocate(real_token_reference, source=token)
      else if (.not. same_type_as(token, real_token_reference)) then
        error stop "real specific local type changed"
      end if
    end select
    if (.not. allocated(canonical_token)) then
      allocate(canonical_token, source=token)
      is_canonical = .true.
    else
      is_canonical = same_type_as(token, canonical_token)
    end if
    payload = token%value
  end subroutine

  generic recursive subroutine host_chain(x, level, parent_reader, ancestor_reader, observed, distinct)
    type(integer, real), intent(in) :: x
    integer, intent(in) :: level
    procedure(reader_interface), optional :: parent_reader
    procedure(reader_interface), optional :: ancestor_reader
    integer, intent(inout) :: observed(6)
    logical, intent(inout) :: distinct(3)
    procedure(reader_interface), pointer :: mine

    mine => read_host
    if (.not. associated(mine, read_host)) error stop "own internal procedure identity"

    select case (level)
    case (0)
      if (present(parent_reader) .or. present(ancestor_reader)) error stop "root readers"
      observed(1) = mine()
      call host_chain(15.0, 1, parent_reader=read_host, observed=observed, distinct=distinct)
    case (1)
      if (.not. present(parent_reader)) error stop "missing parent reader"
      if (present(ancestor_reader)) error stop "unexpected ancestor reader"
      observed(2) = mine()
      observed(3) = parent_reader()
      distinct(1) = .not. associated(mine, parent_reader)
      call host_chain(9, 2, parent_reader=read_host, ancestor_reader=parent_reader, &
                      observed=observed, distinct=distinct)
    case (2)
      if (.not. present(parent_reader) .or. .not. present(ancestor_reader)) then
        error stop "missing live readers"
      end if
      observed(4) = mine()
      observed(5) = parent_reader()
      observed(6) = ancestor_reader()
      distinct(2) = .not. associated(mine, parent_reader)
      distinct(3) = .not. associated(mine, ancestor_reader)
    case default
      error stop "unexpected host-chain level"
    end select
  contains
    integer function read_host()
      read_host = int(x)
    end function
  end subroutine
end module

program audit_language_specialization_identity_p
  use audit_language_specialization_identity_m
  implicit none
  logical :: is_canonical
  integer :: payload, observed(6)
  logical :: distinct(3)

  call observe_local_type(4, is_canonical, payload)
  if (.not. is_canonical .or. payload /= 4) error stop "first integer local type"
  call observe_local_type(7, is_canonical, payload)
  if (.not. is_canonical .or. payload /= 7) error stop "same integer local type"
  call observe_local_type(1.5, is_canonical, payload)
  if (is_canonical .or. payload /= 15) error stop "fresh real local type"
  call observe_local_type(2.5, is_canonical, payload)
  if (is_canonical .or. payload /= 25) error stop "stable real local type"

  observed = -1
  distinct = .false.
  call host_chain(7, 0, observed=observed, distinct=distinct)
  if (any(observed /= [7, 15, 7, 9, 15, 7])) error stop "host capture values"
  if (.not. all(distinct)) error stop "internal procedure host identity"

  print '(a)', 'TEST-PASS: audit-language-specialization-identity'
end program
