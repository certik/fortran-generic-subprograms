! A dummy procedure of a generic subprogram has an explicit interface (C1585).
! The interface is interpreted in each specific, so it can use TYPEOF of the
! generic dummy.
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
end module

program dummy_procedure_p
  use, intrinsic :: iso_fortran_env, only: int32, int64
  use dummy_procedure_m
  implicit none
  if (int32 <= 0 .or. int64 <= 0) error stop "need int32 and int64"
  if (apply(double32, 3_int32) /= 6_int32) error stop "int32"
  if (apply(double64, 3_int64) /= 6_int64) error stop "int64"
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
end program
