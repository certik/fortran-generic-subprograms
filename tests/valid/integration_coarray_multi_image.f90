! TEST-RULE: 8.5.17 11.6 15.6.2.4
! TEST-IMAGES: 2
! This case requires an actual two-image launcher and checks remote data for
! both integer and real type-generated coarray specifics.
program integration_coarray_multi_image_p
  implicit none
  integer :: integer_value[*]
  real :: real_value[*]
  integer :: peer

  if (num_images() /= 2) error stop "requires exactly two images"
  integer_value = 10*this_image()
  real_value = 1.5*this_image()
  sync all
  peer = 3 - this_image()
  if (remote_value(integer_value, peer) /= real(10*peer)) then
    error stop "remote integer coarray"
  end if
  if (remote_value(real_value, peer) /= 1.5*peer) then
    error stop "remote real coarray"
  end if
  sync all
contains
  generic function remote_value(x, image) result(value)
    type(integer, real), intent(in), rank(0) :: x[*]
    integer, intent(in) :: image
    real :: value
    value = real(x[image])
  end function
end program
