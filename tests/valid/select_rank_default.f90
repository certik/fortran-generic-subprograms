! TEST-RULE: R831 R832 R833 R1150 R1152 11.1.10
! TEST-PASS: select_rank_default
! RANK list, range, and RANK DEFAULT. A rank that matches no list uses the
! default. No match and no default would leave the assignment unmade; here
! every rank of the dummy matches something (11.1.10).
module select_rank_default_m
  implicit none
contains
  generic function code(x) result(n)
    integer, intent(in), rank(0:3) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      n = 0
    rank (2)
      n = 2
    rank default
      n = -1
    end select
  end function
end module

program select_rank_default_p
  use select_rank_default_m
  implicit none
  integer :: r1(1), r2(1, 1), r3(1, 1, 1)
  if (code(0) /= 0) error stop "rank 0"
  if (code(r1) /= -1) error stop "rank 1 default"
  if (code(r2) /= 2) error stop "rank 2"
  if (code(r3) /= -1) error stop "rank 3 default"
  print '(a)', 'TEST-PASS: select_rank_default'
end program
