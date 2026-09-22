! TEST-RULE: R1150 R1155 R1168 C1181 11.1.14 15.6.2.4
! Named EXIT, RETURN, and named loops occur only in selected blocks. BLOCK
! declarations contain type/rank-specific specification expressions that must
! be pruned before semantic analysis of every other specific.
module language_selection_control_m
  implicit none
contains
  generic function exit_selected(x) result(n)
    type(integer, real), intent(in) :: x
    integer :: n
    n = -1
    chosen: select generic type (x)
    declared type is (integer) chosen
      n = x
      exit chosen
      n = -100
    declared type is (real) chosen
      n = nint(x)
      exit chosen
      n = -200
    end select chosen
  end function

  generic subroutine return_selected(x, n)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: n
    select generic type (x)
    declared type is (integer)
      n = 10 + x
      return
    declared type is (real)
      n = 20 + nint(x)
      return
    end select
    n = -1
  end subroutine

  generic function selected_loops(x) result(n)
    integer, rank(1:2), intent(in) :: x
    integer :: n, i, j
    n = 0
    select generic rank (x)
    rank (1)
      vector_loop: do i = 1, size(x)
        if (i == 2) cycle vector_loop
        n = n + x(i)
      end do vector_loop
    rank (2)
      row_loop: do j = 1, size(x, 2)
        column_loop: do i = 1, size(x, 1)
          n = n + x(i, j)
          if (n >= 3) exit row_loop
        end do column_loop
      end do row_loop
    end select
  end function

  generic function type_block_spec(x) result(n)
    type(integer, real), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer)
      block
        integer :: local(max(1, x))
        local = x
        n = size(local) + sum(local)
      end block
    declared type is (real)
      block
        real :: local(max(1, nint(x)))
        local = x
        n = size(local) + nint(sum(local))
      end block
    end select
  end function

  generic function rank_block_spec(x) result(n)
    integer, rank(1:2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (1)
      block
        integer :: local(size(x, 1))
        local = x
        n = size(local) + sum(local)
      end block
    rank (2)
      block
        integer :: local(size(x, 1), size(x, 2))
        local = x
        n = size(local) + sum(local)
      end block
    end select
  end function
end module

program language_selection_control_p
  use language_selection_control_m
  implicit none
  integer :: n
  integer :: v(3), m(2, 2)

  v = [2, 3, 4]
  m = reshape([1, 2, 3, 4], [2, 2])
  if (exit_selected(7) /= 7) error stop "named exit integer"
  if (exit_selected(3.0) /= 3) error stop "named exit real"
  call return_selected(5, n)
  if (n /= 15) error stop "selected return integer"
  call return_selected(6.0, n)
  if (n /= 26) error stop "selected return real"
  if (selected_loops(v) /= 6) error stop "named vector loop"
  if (selected_loops(m) /= 3) error stop "named matrix loops"
  if (type_block_spec(3) /= 12) error stop "integer block declaration"
  if (type_block_spec(2.0) /= 6) error stop "real block declaration"
  if (rank_block_spec(v) /= 12) error stop "rank1 block declaration"
  if (rank_block_spec(m) /= 14) error stop "rank2 block declaration"
end program
