! TEST-RULE: C1568 C1570 15.6.2.4 19.10.2
! TEST-DRAFT: generic-bind-c
! NAME="" gives every generated specific no binding label, so the scalar
! and rank-one specifics do not create duplicate external identifiers.
module integration_generic_bind_c_empty_name_m
  implicit none
  private
  public :: observe_rank, observed_rank
  integer :: observed_rank = -1
contains
  generic subroutine observe_rank(x) bind(c, name="")
    type(*), rank(0:1), intent(in) :: x
    observed_rank = rank(x)
  end subroutine
end module

program integration_generic_bind_c_empty_name_p
  use integration_generic_bind_c_empty_name_m
  implicit none
  integer :: scalar, vector(3)
  scalar = 17
  vector = [1, 2, 3]
  call observe_rank(scalar)
  if (observed_rank /= 0) error stop "empty-name scalar specific"
  call observe_rank(vector)
  if (observed_rank /= 1) error stop "empty-name rank-one specific"
end program
