! TEST-RULE: C826 C877 8.5.17 17.10.2.24
! TEST-DRAFT: extended-rank-limit
! Under the documented extended-rank interpretation, a named constant and
! an allocatable object can have processor-dependent RANK(MAX_RANK()).
module integration_extended_rank_limit_m
  use, intrinsic :: iso_fortran_env, only: max_rank
  implicit none
  integer :: i
  integer, parameter :: extents(max_rank()) = &
    [(merge(2, 1, i == max_rank()), i=1, max_rank())]
  integer, parameter, rank(max_rank()) :: source = &
    reshape([11, 22], extents)
contains
  generic function inspect_high_rank(x) result(code)
    integer, intent(in), rank(max_rank():max_rank()) :: x
    integer :: code
    integer, allocatable :: flat(:)
    if (rank(x) /= max_rank()) error stop "processor-dependent rank"
    if (any(shape(x) /= extents)) error stop "processor-dependent shape"
    if (any(lbound(x) /= 1)) error stop "processor-dependent bounds"
    flat = pack(x, .true.)
    if (any(flat /= [11, 22])) error stop "processor-dependent data"
    code = sum(flat)
  end function
end module

program integration_extended_rank_limit_p
  use, intrinsic :: iso_fortran_env, only: max_rank
  use integration_extended_rank_limit_m
  implicit none
  integer, allocatable, rank(max_rank()) :: value
  allocate(value, source=source)
  if (inspect_high_rank(value) /= 33) error stop "extended rank result"
end program
