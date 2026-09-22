! TEST-RULE: C1585 15.3.2.3 15.4.3.6 15.6.2.4
! TEST-REQUIRES: int32 int64
! Dummy callbacks have explicit interfaces specialized from the generic
! data dummy. Function results, subroutines, procedure declarations,
! procedure pointers, and an optional nongeneric callback all execute.
module dummy_procedure_m
  use, intrinsic :: iso_fortran_env, only: int32, int64
  implicit none
contains
  generic function apply(f, n) result(r)
    integer([int32, int64]), intent(in) :: n
    interface
      pure function f(a) result(b)
        import n
        typeof(n), intent(in) :: a
        typeof(n) :: b
      end function
    end interface
    typeof(n) :: r
    r = f(n)
  end function

  generic subroutine transform(x, action, after)
    integer([int32, int64]), rank(1:2), intent(inout) :: x
    abstract interface
      subroutine callback(a)
        import x
        typeof(x), rank(rank(x)), intent(inout) :: a
      end subroutine
    end interface
    procedure(callback) :: action
    procedure(callback), optional :: after
    procedure(callback), pointer :: selected
    selected => action
    call selected(x)
    if (present(after)) call after(x)
  end subroutine

  generic function apply_array(f, x) result(r)
    integer([int32, int64]), rank(1:2), intent(in) :: x
    abstract interface
      function array_function(a) result(b)
        import x
        typeof(x), rank(rank(x)), intent(in) :: a
        typeof(x), allocatable, rank(rank(x)) :: b
      end function
    end interface
    procedure(array_function) :: f
    typeof(x), allocatable, rank(rank(x)) :: r
    r = f(x)
  end function
end module

program dummy_procedure_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use dummy_procedure_m
  implicit none
  integer(int32) :: vector32(3), matrix32(2, 2)
  integer(int64) :: vector64(2), matrix64(2, 2)
  integer(int32), allocatable :: result32(:), result32_matrix(:, :)
  integer(int64), allocatable :: result64_vector(:), result64(:, :)
  abstract interface
    subroutine vector32_callback(a)
      import int32
      integer(int32), intent(inout) :: a(:)
    end subroutine
  end interface
  procedure(vector32_callback), pointer :: callback_pointer

  if (apply(double32, 3_int32) /= 6_int32) error stop "int32 function"
  if (apply(double64, 3_int64) /= 6_int64) error stop "int64 function"

  vector32 = [1_int32, 2_int32, 3_int32]
  callback_pointer => add_ten32_vector
  call transform(vector32, callback_pointer)
  if (any(vector32 /= [11_int32, 12_int32, 13_int32])) then
    error stop "procedure pointer callback"
  end if

  vector64 = [4_int64, 5_int64]
  call transform(vector64, add_five64_vector)
  if (any(vector64 /= [9_int64, 10_int64])) then
    error stop "int64 rank-one callback"
  end if

  matrix32 = reshape([1_int32, 2_int32, 3_int32, 4_int32], [2, 2])
  call transform(matrix32, negate32_matrix)
  if (any(matrix32 /= -reshape([1_int32, 2_int32, 3_int32, 4_int32], [2, 2]))) then
    error stop "int32 rank-two callback"
  end if

  matrix64 = reshape([1_int64, 2_int64, 3_int64, 4_int64], [2, 2])
  call transform(matrix64, double64_matrix, add_one64_matrix)
  if (any(matrix64 /= reshape([3_int64, 5_int64, 7_int64, 9_int64], [2, 2]))) then
    error stop "rank-dependent subroutine callback"
  end if

  result32 = apply_array(copy_plus_one32_vector, vector32)
  if (.not. allocated(result32)) error stop "rank1 callback result allocation"
  if (any(result32 /= [12_int32, 13_int32, 14_int32])) then
    error stop "rank1 callback result values"
  end if
  result64_vector = apply_array(copy_plus_one64_vector, vector64)
  if (.not. allocated(result64_vector)) then
    error stop "int64 rank1 callback result allocation"
  end if
  if (any(result64_vector /= [10_int64, 11_int64])) then
    error stop "int64 rank1 callback result values"
  end if
  result32_matrix = apply_array(copy_plus_one32_matrix, matrix32)
  if (.not. allocated(result32_matrix)) then
    error stop "int32 rank2 callback result allocation"
  end if
  if (any(shape(result32_matrix) /= [2, 2])) then
    error stop "int32 rank2 callback result shape"
  end if
  if (any(result32_matrix /= matrix32 + 1_int32)) then
    error stop "int32 rank2 callback result values"
  end if
  result64 = apply_array(copy_plus_one64_matrix, matrix64)
  if (.not. allocated(result64)) error stop "rank2 callback result allocation"
  if (any(shape(result64) /= [2, 2])) error stop "rank2 callback result shape"
  if (any(result64 /= matrix64 + 1_int64)) error stop "rank2 callback result values"
contains
  pure function double32(a) result(b)
    integer(int32), intent(in) :: a
    integer(int32) :: b
    b = a + a
  end function

  pure function double64(a) result(b)
    integer(int64), intent(in) :: a
    integer(int64) :: b
    b = a + a
  end function

  subroutine add_ten32_vector(a)
    integer(int32), intent(inout) :: a(:)
    a = a + 10_int32
  end subroutine

  subroutine double64_matrix(a)
    integer(int64), intent(inout) :: a(:, :)
    a = 2_int64*a
  end subroutine

  subroutine add_five64_vector(a)
    integer(int64), intent(inout) :: a(:)
    a = a + 5_int64
  end subroutine

  subroutine negate32_matrix(a)
    integer(int32), intent(inout) :: a(:, :)
    a = -a
  end subroutine

  subroutine add_one64_matrix(a)
    integer(int64), intent(inout) :: a(:, :)
    a = a + 1_int64
  end subroutine

  function copy_plus_one32_vector(a) result(b)
    integer(int32), intent(in) :: a(:)
    integer(int32), allocatable :: b(:)
    allocate(b, source=a + 1_int32)
  end function

  function copy_plus_one64_matrix(a) result(b)
    integer(int64), intent(in) :: a(:, :)
    integer(int64), allocatable :: b(:, :)
    allocate(b, source=a + 1_int64)
  end function

  function copy_plus_one64_vector(a) result(b)
    integer(int64), intent(in) :: a(:)
    integer(int64), allocatable :: b(:)
    allocate(b, source=a + 1_int64)
  end function

  function copy_plus_one32_matrix(a) result(b)
    integer(int32), intent(in) :: a(:, :)
    integer(int32), allocatable :: b(:, :)
    allocate(b, source=a + 1_int32)
  end function
end program
