! TEST-RULE: C7132 7.5.10 14.2.2 15.4.3.4.1 15.5.5.1 15.5.5.2 15.6.2.4
! TEST-PASS: integration_name_resolution
! USE ONLY renaming merges generic interfaces from different modules.
module integration_resolution_integer_m
  implicit none
contains
  generic integer function dispatch(x)
    integer, rank(0:0), intent(in) :: x
    dispatch = x + 10
  end function
end module

module integration_resolution_real_m
  implicit none
contains
  generic real function dispatch(x)
    real, rank(0:0), intent(in) :: x
    dispatch = x + 0.5
  end function
end module

module integration_host_fallback_m
  implicit none
contains
  generic integer function choose(x)
    integer, rank(0:0), intent(in) :: x
    choose = x + 20
  end function

  integer function exercise_host_fallback() result(code)
    interface choose
      procedure choose_real
    end interface
    code = 100*choose(3) + nint(choose(1.5))
  contains
    real function choose_real(x)
      real, intent(in) :: x
      choose_real = x + 0.5
    end function
  end function
end module

module integration_private_metadata_m
  implicit none
  private
  public :: make_secret, describe
  type :: secret
    integer :: value
  end type
contains
  function make_secret(value) result(x)
    integer, intent(in) :: value
    type(secret) :: x
    x%value = value
  end function

  generic integer function describe(x)
    type(secret), intent(in) :: x
    describe = 100 + x%value
  end function

  generic integer function describe(x)
    integer, rank(0:0), intent(in) :: x
    describe = 200 + x
  end function
end module

module integration_constructor_extension_m
  implicit none
  type :: token
    integer :: value = 0
  end type
contains
  generic function token(raw) result(value)
    integer, intent(in) :: raw
    type(token) :: value
    value%value = raw + 100
  end function

  generic function token(text) result(value)
    character(len=*), intent(in) :: text
    type(token) :: value
    value%value = len_trim(text)
  end function
end module

program integration_name_resolution_p
  use integration_resolution_integer_m, only: route => dispatch
  use integration_resolution_real_m, only: route => dispatch
  use integration_host_fallback_m, only: exercise_host_fallback
  use integration_private_metadata_m, only: make_secret, describe
  use integration_constructor_extension_m, only: token
  implicit none
  type(token) :: from_integer_function, from_constructor, from_character_function

  if (route(5) /= 15) error stop "merged integer generic"
  if (route(1.5) /= 2.0) error stop "merged real generic"
  if (exercise_host_fallback() /= 2302) error stop "host generic fallback"
  if (describe(make_secret(7)) /= 107) error stop "private type metadata"
  if (describe(8) /= 208) error stop "public integer specific"

  from_integer_function = token(9)
  from_constructor = token(value=9)
  from_character_function = token("abcd")
  if (from_integer_function%value /= 109) then
    error stop "integer generic beats positional constructor"
  end if
  if (from_constructor%value /= 9) error stop "keyword structure constructor"
  if (from_character_function%value /= 4) error stop "character extension"
  print '(a)', 'TEST-PASS: integration_name_resolution'
end program
