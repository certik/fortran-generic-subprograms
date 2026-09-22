! Invalid: C803. *char-length is allowed only when every type in the
! generic-type-spec is character.
module char_length_on_noncharacter_m
  implicit none
contains
  generic subroutine s(x)
    type(integer, real) :: x*1
  end subroutine
end module
