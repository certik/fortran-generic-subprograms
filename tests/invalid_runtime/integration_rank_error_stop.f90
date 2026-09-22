! TEST-RULE: 8.5.17 11.4 15.6.2.4
! TEST-STOP: rank-specialization
! Only the rank-two generated specific intentionally error-terminates.
program integration_rank_error_stop_p
  use, intrinsic :: iso_fortran_env, only: output_unit
  implicit none
  integer :: matrix(2, 2)
  matrix = reshape([1, 2, 3, 4], [2, 2])
  call require_vector(matrix)
  print '(a)', "TEST-UNEXPECTED-RETURN: rank-specialization"
contains
  generic subroutine require_vector(x)
    integer, intent(in), rank(1:2) :: x
    select generic rank (x)
    rank (1)
      if (sum(x) < 0) error stop "unreachable vector error"
    rank (2)
      print '(a)', "TEST-STOP: rank-specialization"
      flush(output_unit)
      error stop "rank-two specialization rejected by this application"
    end select
  end subroutine
end program
