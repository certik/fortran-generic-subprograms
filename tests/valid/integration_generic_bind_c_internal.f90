! TEST-RULE: C1566 C1568 C1570 15.6.2.4 19.10.2
! TEST-DRAFT: generic-bind-c
! An internal BIND(C) procedure without NAME= has no binding label.
program integration_generic_bind_c_internal_p
  implicit none
  integer :: observed_rank, scalar, vector(2)
  observed_rank = -1
  scalar = 4
  vector = [5, 6]
  call observe_internal(scalar)
  if (observed_rank /= 0) error stop "internal scalar specific"
  call observe_internal(vector)
  if (observed_rank /= 1) error stop "internal rank-one specific"
contains
  generic subroutine observe_internal(x) bind(c)
    type(*), rank(0:1), intent(in) :: x
    observed_rank = rank(x)
  end subroutine
end program
