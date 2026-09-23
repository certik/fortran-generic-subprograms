! TEST-RULE: C877 8.5.3 8.5.14 9.7.1 10.2.1.3 15.6.2.4
! TEST-PASS: integration_allocatable_pointer_results
! Allocatable and pointer results follow generic rank, preserve data and
! lengths, handle zero extents, and can alias a noncontiguous target.
module integration_allocatable_pointer_results_m
  implicit none
contains
  generic function clone_integer(x) result(y)
    integer, intent(in), rank(0:2) :: x
    integer, allocatable, rank(rank(x)) :: y
    allocate(y, source=x)
  end function

  generic function alias_integer(x) result(p)
    integer, target, intent(inout), rank(0:2) :: x
    integer, pointer, rank(rank(x)) :: p
    p => x
  end function

  generic function clone_text(x) result(y)
    character(len=*), intent(in), rank(0:1) :: x
    character(len=:), allocatable, rank(rank(x)) :: y
    allocate(y, source=x)
  end function
end module

program integration_allocatable_pointer_results_p
  use integration_allocatable_pointer_results_m
  implicit none
  integer, target :: scalar, vector(0:3), storage(9)
  integer, target :: matrix(0:1, 4:6)
  integer, allocatable :: scalar_copy, vector_copy(:)
  integer, allocatable :: empty_copy(:, :), matrix_copy(:, :)
  integer, pointer :: scalar_alias, strided_alias(:), matrix_alias(:, :)
  character(len=:), allocatable :: text_copy
  character(len=:), allocatable :: words_copy(:)
  character(len=3) :: words(2)
  integer :: i

  scalar = 7
  scalar_copy = clone_integer(scalar)
  if (.not. allocated(scalar_copy) .or. scalar_copy /= 7) then
    error stop "scalar sourced allocation"
  end if
  vector = [3, 6, 9, 12]
  vector_copy = clone_integer(vector(3:0:-1))
  if (.not. allocated(vector_copy)) error stop "rank1 sourced allocation"
  if (any(lbound(vector_copy) /= [1]) .or. &
      any(ubound(vector_copy) /= [4])) error stop "rank1 clone bounds"
  if (any(vector_copy /= [12, 9, 6, 3])) error stop "rank1 clone values"

  matrix = reshape([(i, i=1, 6)], [2, 3])
  matrix_copy = clone_integer(matrix)
  if (any(shape(matrix_copy) /= [2, 3])) error stop "matrix clone shape"
  if (any(lbound(matrix_copy) /= [1, 1])) error stop "matrix clone bounds"
  if (any(matrix_copy /= reshape([(i, i=1, 6)], [2, 3]))) then
    error stop "matrix clone values"
  end if
  empty_copy = clone_integer(matrix(1:0, 4:6))
  if (any(shape(empty_copy) /= [0, 3])) error stop "zero-extent clone"
  if (any(ubound(empty_copy) /= [0, 3])) error stop "zero-extent bounds"

  scalar_alias => alias_integer(scalar)
  if (.not. associated(scalar_alias, scalar)) error stop "scalar pointer result"
  scalar_alias = 19
  if (scalar /= 19) error stop "scalar pointer result update"

  storage = [(i, i=1, 9)]
  strided_alias => alias_integer(storage(1:9:2))
  if (.not. associated(strided_alias)) error stop "strided pointer result"
  if (any(strided_alias /= [1, 3, 5, 7, 9])) error stop "strided pointer values"
  strided_alias = strided_alias + 100
  if (any(storage(1:9:2) /= [101, 103, 105, 107, 109])) then
    error stop "strided pointer result update"
  end if
  if (any(storage(2:8:2) /= [2, 4, 6, 8])) error stop "strided isolation"

  matrix_alias => alias_integer(matrix)
  if (.not. associated(matrix_alias, matrix)) error stop "rank2 pointer result"
  if (any(lbound(matrix_alias) /= [1, 1]) .or. &
      any(ubound(matrix_alias) /= [2, 3])) error stop "rank2 pointer bounds"
  if (matrix_alias(2, 3) /= 6) error stop "rank2 pointer values"
  matrix_alias(1, 2) = 77
  if (matrix(0, 5) /= 77) error stop "rank2 pointer update"
  if (matrix(1, 5) /= 4) error stop "rank2 pointer isolation"

  text_copy = clone_text("hello")
  if (.not. allocated(text_copy)) error stop "text allocation"
  if (len(text_copy) /= 5 .or. text_copy /= "hello") error stop "text value"
  words = ["one", "two"]
  words_copy = clone_text(words)
  if (.not. allocated(words_copy)) error stop "text array allocation"
  if (len(words_copy) /= 3) error stop "text array length"
  if (any(words_copy /= words)) error stop "text array values"
  print '(a)', 'TEST-PASS: integration_allocatable_pointer_results'
end program
