! TEST-RULE: 15.4.3.4.5 15.5.2 15.6.2.4
! Keywords and optional nongeneric dummies retain their names and presence
! independently in every generated specific.
module integration_keyword_optional_m
  implicit none
contains
  generic function adjust(value, scale, offset) result(answer)
    type(integer, real), intent(in) :: value
    integer, intent(in), optional :: scale, offset
    typeof(value) :: answer
    integer :: actual_scale, actual_offset
    actual_scale = 1
    actual_offset = 0
    if (present(scale)) actual_scale = scale
    if (present(offset)) actual_offset = offset
    answer = actual_scale*value + actual_offset
  end function
end module

program integration_keyword_optional_p
  use integration_keyword_optional_m
  implicit none
  if (adjust(4) /= 4) error stop "all optional absent"
  if (adjust(value=4, offset=3) /= 7) error stop "keyword optional gap"
  if (adjust(offset=2, value=5, scale=3) /= 17) then
    error stop "reordered integer keywords"
  end if
  if (adjust(value=1.5, scale=2) /= 3.0) error stop "real optional"
  if (adjust(offset=1, scale=2, value=1.5) /= 4.0) then
    error stop "reordered real keywords"
  end if
end program
